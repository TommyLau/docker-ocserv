FROM ubuntu:14.04

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		autoconf autogen ca-certificates curl gcc \
		libdbus-1-dev libgnutls28-dev libnl-route-3-dev libpam0g-dev libreadline-dev libwrap0-dev \
		make pkg-config xz-utils \
# NOT FOUND?
# 		libfreeradius-client-dev liblz4-dev libsystemd-daemon-dev
# Use included:
# 		libhttp-parser-dev libpcl1-dev libprotobuf-c0-dev libtalloc-dev
	&& rm -r /var/lib/apt/lists/*

ENV OC_VERSION 0.9.0.1
ENV LZ4_VERSION r127

# Add the missing pkg-config file
#COPY libprotobuf-c.pc /usr/lib/pkgconfig/

RUN set -x \
	&& curl -SL "https://github.com/Cyan4973/lz4/archive/$LZ4_VERSION.tar.gz" -o lz4.tar.gz \
	&& curl -SL "ftp://ftp.infradead.org/pub/ocserv/ocserv-$OC_VERSION.tar.xz" -o ocserv.tar.xz \
	&& curl -SL "ftp://ftp.infradead.org/pub/ocserv/ocserv-$OC_VERSION.tar.xz.sig" -o ocserv.tar.xz.sig \
	&& gpg --keyserver pgp.mit.edu --recv-key 96865171 \
	&& gpg --verify ocserv.tar.xz.sig \
	&& mkdir -p /usr/src/lz4 \
	&& mkdir -p /usr/src/ocserv \
	&& tar -xf lz4.tar.gz -C /usr/src/lz4 --strip-components=1 \
	&& tar -xf ocserv.tar.xz -C /usr/src/ocserv --strip-components=1 \
	&& rm lz4.tar.gz \
	&& rm ocserv.tar.xz* \
	&& cd /usr/src/lz4 \
	&& make -j"$(nproc)" \
	&& make install \
	&& make clean \
	&& cd /usr/src/ocserv \
	&& ./configure --enable-linux-namespaces \
	&& make -j"$(nproc)" \
	&& make install \
	&& make clean

EXPOSE 443

