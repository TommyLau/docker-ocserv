# docker-ocserv

## 说明
使用此容器的前提是你已经在公网环境搭建了FRP的服务端
 此容器用途：
    通过公网环境访问企业内部服务

 此容器包含：  
    OpenConnect VPN Server(ocserv)： ocserv vpn server
    FRP： FRP 内网穿透客户端
    SSHD： 容器内部sshd服务，主要用来避免企业内部操作审计

### What is OpenConnect Server?
[OpenConnect server (ocserv)](http://www.infradead.org/ocserv/) is an SSL VPN server. It implements the OpenConnect SSL VPN protocol, and has also (currently experimental) compatibility with clients using the [AnyConnect SSL VPN](http://www.cisco.com/c/en/us/support/security/anyconnect-vpn-client/tsd-products-support-series-home.html) protocol.

### What is FRP
[FRP](https://github.com/fatedier/frp/blob/master/README_zh.md)是一个可用于内网穿透的高性能的反向代理应用，支持 tcp, udp, http, https 协议。

### What is SSHD
sshd命令是openssh软件套件中的服务器守护进程

### Update on 2018/11/03
添加docker中的sshd服务,并且开启反向代理(sshd + frpc)
添加对于宿主机的ssh端口的反向代理(frpc)

### Update on 2018/11/02
Update to version 0.12.1 and use Alpine 3.7 as base image
Add Frpc-0.16.0 and config to base image


## Environment Variables

### Ocserv Variables

All the variables to this image is optional, which means you don't have to type in any environment variables, and you can have a OpenConnect Server out of the box! However, if you like to config the ocserv the way you like it, here's what you wanna know.

`CA_CN`, this is the common name used to generate the CA(Certificate Authority).(选填)

`CA_ORG`, this is the organization name used to generate the CA.(选填)

`CA_DAYS`, this is the expiration days used to generate the CA.(选填)

`SRV_CN`, this is the common name used to generate the server certification.(选填)

`SRV_ORG`, this is the organization name used to generate the server certification.(选填)

`SRV_DAYS`, this is the expiration days used to generate the server certification.(选填)

`NO_TEST_USER`, while this variable is set to not empty, the `test` user will not be created. You have to create your own user with password. The default value is to create `test` user with password `test`.(选填)

The default values of the above environment variables:

|   Variable   |     Default     |
|:------------:|:---------------:|
|  **CA_CN**   |      VPN CA     |
|  **CA_ORG**  |     Big Corp    |
| **CA_DAYS**  |       9999      |
|  **SRV_CN**  | www.example.com |
| **SRV_ORG**  |    My Company   |
| **SRV_DAYS** |       9999      |

### FRP Variables

`server_addr`, frp服务端地址,可以为IP或者domain. 此变量作用在frpc_full.ini.(必填)

`server_port`, frp服务端端口.此变量作用在frpc_full.ini.(必填)

`privilege_token`, frps服务器认证的token. 此变量作用在frpc_full.ini.(必填)

`login_fail_exit`, frpc客户端如果通过上述token登录失败，是否退出. (选填)

`hostname_in_docker`, 将在frps的dashboard上显示的名称,因为在frpc_fill.ini中定义的远端端口为0(随机端口),这里填写hostname_in_docker方便在dashboard上查找对应端口. 此变量作用在frpc_full.ini.(必填)

`ip_out_docker`, 运行此容器的宿主机ip,主要为了用来frp反向代理宿主机或**本局域网中其他主机**的ssh服务.此变量作用在frpc_full.ini.(选填)

`ssh_port_out_docker`, 运行此容器的宿主机端口,主要为了用来frp反向代理宿主机的ssh服务.此变量作用在frpc_full.ini.(选填)


The default values of the above environment variables:

|   Variable   |     Default     |
|:------------:|:---------------:|
| **server_addr** | 0.0.0.0 |
| **server_port** | 7000 |
| **privilege_token** | 405520 |
| **login_fail_exit** | true |
| **hostname_in_docker** | hostname_in_docker |
| **ip_out_docker** | 127.0.0.1  |
| **ssh_port_out_docker** | 22   |

## How to use this image
Get the docker image by running the following commands:

```bash
docker pull registry.cn-hangzhou.aliyuncs.com/sourcegarden/ocserv-fp:v1.8
```

Start an ocserv instance:

```bash
docker run --name ocserv --privileged  -p 1443:443 -p 1443:443/udp \
-e "server_addr=123.57.3.xx" \
-e "hostname_in_docker=test01-local"  \
-e "ip_out_docker=192.168.1.190" \
--restart=always -d \
registry.cn-hangzhou.aliyuncs.com/sourcegarden/ocserv-fp

```

This will start an instance with the a test user named `heaven` and password is also `echoinheaven`.


### Examples for ocserv
**下面将单从ocserv服务讲解如何使用该镜像**
Start an instance out of the box with username `heaven` and password `echoinheaven`

```bash
docker run --name ocserv --privileged -p 443:443 -p 443:443/udp -d registry.cn-hangzhou.aliyuncs.com/sourcegarden/ocserv-fp
```

Start an instance with server name `my.test.com`, `My Test` and `365` days

```bash
docker run --name ocserv --privileged -p 443:443 -p 443:443/udp -e SRV_CN=my.test.com -e SRV_ORG="My Test" -e SRV_DAYS=365 -d registry.cn-hangzhou.aliyuncs.com/sourcegarden/ocserv-fp
```

Start an instance with CA name `My CA`, `My Corp` and `3650` days

```bash
docker run --name ocserv --privileged -p 443:443 -p 443:443/udp -e CA_CN="My CA" -e CA_ORG="My Corp" -e CA_DAYS=3650 -d registry.cn-hangzhou.aliyuncs.com/sourcegarden/ocserv-fp
```

A totally customized instance with both CA and server certification

```bash
docker run --name ocserv --privileged -p 443:443 -p 443:443/udp -e CA_CN="My CA" -e CA_ORG="My Corp" -e CA_DAYS=3650 -e SRV_CN=my.test.com -e SRV_ORG="My Test" -e SRV_DAYS=365 -d registry.cn-hangzhou.aliyuncs.com/sourcegarden/ocserv-fp
```

Start an instance as above but without test user

```bash
docker run --name ocserv --privileged -p 443:443 -p 443:443/udp -e CA_CN="My CA" -e CA_ORG="My Corp" -e CA_DAYS=3650 -e SRV_CN=my.test.com -e SRV_ORG="My Test" -e SRV_DAYS=365 -e NO_TEST_USER=1 -v /some/path/to/ocpasswd:/etc/ocserv/ocpasswd -d registry.cn-hangzhou.aliyuncs.com/sourcegarden/ocserv-fp
```

**WARNING:** The ocserv requires the ocpasswd file to start, if `NO_TEST_USER=1` is provided, there will be no ocpasswd created, which will stop the container immediately after start it. You must specific a ocpasswd file pointed to `/etc/ocserv/ocpasswd` by using the volume argument `-v` by docker as demonstrated above.

#### User operations

All the users opertaions happened while the container is running. If you used a different container name other than `ocserv`, then you have to change the container name accordingly.

##### Add user

If say, you want to create a user named `tommy`, type the following command

```bash
docker exec -ti ocserv ocpasswd -c /etc/ocserv/ocpasswd -g "Route,All" tommy
Enter password:
Re-enter password:
```

When prompt for password, type the password twice, then you will have the user with the password you want.

>`-g "Route,ALL"` means add user `tommy` to group `Route` and group `All`

##### Delete user

Delete user is similar to add user, just add another argument `-d` to the command line

```bash
docker exec -ti ocserv ocpasswd -c /etc/ocserv/ocpasswd -d test
```

The above command will delete the default user `test`, if you start the instance without using environment variable `NO_TEST_USER`.

##### Change password

Change password is exactly the same command as add user, please refer to the command mentioned above.
