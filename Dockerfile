FROM alpine:3.7
ENV OC_VERSION=0.12.1
ENV ROOT_PASSWORD rootA

RUN buildDeps=" \
		curl \
		g++ \
		gnutls-dev \
		gpgme \
		libev-dev \
		libnl3-dev \
		libseccomp-dev \
		linux-headers \
		linux-pam-dev \
		lz4-dev \
		make \
		readline-dev \
		tar \
		xz \
	"; \
	set -x \
	&& sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
	&& apk add openssh \
	&& apk add --update --virtual .build-deps $buildDeps  \
	&& sed -i s/#PermitRootLogin.*/PermitRootLogin\ yes/ /etc/ssh/sshd_config \
	&& echo "root:${ROOT_PASSWORD}" | chpasswd \
	&& curl -SL "ftp://ftp.infradead.org/pub/ocserv/ocserv-$OC_VERSION.tar.xz" -o ocserv.tar.xz \
	&& curl -SL "ftp://ftp.infradead.org/pub/ocserv/ocserv-$OC_VERSION.tar.xz.sig" -o ocserv.tar.xz.sig \
#	&& gpg --keyserver pgp.mit.edu --recv-key 7F343FA7 \
#	&& gpg --keyserver pgp.mit.edu --recv-key 96865171 \
#	&& gpg --verify ocserv.tar.xz.sig \
	&& mkdir -p /usr/src/ocserv \
	&& tar -xf ocserv.tar.xz -C /usr/src/ocserv --strip-components=1 \
	&& rm ocserv.tar.xz* \
	&& cd /usr/src/ocserv \
	&& ./configure \
	&& make \
	&& make install \
	&& mkdir -p /etc/ocserv \
	&& cp /usr/src/ocserv/doc/sample.config /etc/ocserv/ocserv.conf \
	&& cd / \
	&& rm -fr /usr/src/ocserv \
	&& runDeps="$( \
		scanelf --needed --nobanner /usr/local/sbin/ocserv \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| xargs -r apk info --installed \
			| sort -u \
		)" \
	&& apk add --virtual .run-deps $runDeps gnutls-utils iptables libnl3 readline \
	&& apk del .build-deps \
	&& rm -rf /var/cache/apk/*

# Setup config
COPY groupinfo.txt /tmp/
RUN set -x \
	&& sed -i 's/\.\/sample\.passwd/\/etc\/ocserv\/ocpasswd/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/\(max-same-clients = \)2/\110/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/\.\.\/tests/\/etc\/ocserv/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/#\(compression.*\)/\1/' /etc/ocserv/ocserv.conf \
	&& sed -i '/^ipv4-network = /{s/192.168.1.0/192.168.99.0/}' /etc/ocserv/ocserv.conf \
	&& sed -i 's/192.168.1.2/8.8.8.8/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/^route/#route/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/^no-route/#no-route/' /etc/ocserv/ocserv.conf \
	&& sed -i '/\[vhost:www.example.com\]/,$d' /etc/ocserv/ocserv.conf \
	&& mkdir -p /etc/ocserv/config-per-group \
	&& cat /tmp/groupinfo.txt >> /etc/ocserv/ocserv.conf \
	&& rm -fr /tmp/cn-no-route.txt \
	&& rm -fr /tmp/groupinfo.txt

WORKDIR /etc/ocserv

# Frp frp_0.16.0_linux_386.tar.gz
COPY frpc /usr/bin/frpc
COPY frpc_full.ini /etc/frp/frpc_full.ini
COPY All /etc/ocserv/config-per-group/All
COPY cn-no-route.txt /etc/ocserv/config-per-group/Route
COPY docker-entrypoint.sh /entrypoint.sh

RUN chmod a+x /usr/bin/frpc

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 443
CMD ["ocserv", "-c", "/etc/ocserv/ocserv.conf", "-f"]
