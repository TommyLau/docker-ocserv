# docker-ocserv

docker-ocserv is an OpenConnect VPN Server boxed in a Docker image base on [Tommy Lau](mailto:tommy@gen-new.com).

## Update on 2018/11/02

Update to version 0.12.1 and use Alpine 3.7 as base image

Add Frpc-0.16.0 and config to base image


## What is OpenConnect Server?

[OpenConnect server (ocserv)](http://www.infradead.org/ocserv/) is an SSL VPN server. It implements the OpenConnect SSL VPN protocol, and has also (currently experimental) compatibility with clients using the [AnyConnect SSL VPN](http://www.cisco.com/c/en/us/support/security/anyconnect-vpn-client/tsd-products-support-series-home.html) protocol.

## How to use this image

Get the docker image by running the following commands:

```bash
docker pull registry.cn-hangzhou.aliyuncs.com/sourcegarden/ocserv-fp:v1.7
```

Start an ocserv instance:

```bash
docker run --name ocserv --privileged -p 1443:443 -p 1443:443/udp -e "server_addr=<ip/domain>" -e "privilege_token=<token_on_frps>" -e "hostname_in_docker=<name_on_frpc>" -d  registry.cn-hangzhou.aliyuncs.com/sourcegarden/ocserv-fp:v1.7
```

This will start an instance with the a test user named `heaven` and password is also `null`.

### Environment Variables

All the variables to this image is optional, which means you don't have to type in any environment variables, and you can have a OpenConnect Server out of the box! However, if you like to config the ocserv the way you like it, here's what you wanna know.

`CA_CN`, this is the common name used to generate the CA(Certificate Authority).

`CA_ORG`, this is the organization name used to generate the CA.

`CA_DAYS`, this is the expiration days used to generate the CA.

`SRV_CN`, this is the common name used to generate the server certification.

`SRV_ORG`, this is the organization name used to generate the server certification.

`SRV_DAYS`, this is the expiration days used to generate the server certification.

`NO_TEST_USER`, while this variable is set to not empty, the `test` user will not be created. You have to create your own user with password. The default value is to create `test` user with password `test`.

The default values of the above environment variables:

|   Variable   |     Default     |
|:------------:|:---------------:|
|  **CA_CN**   |      VPN CA     |
|  **CA_ORG**  |     Big Corp    |
| **CA_DAYS**  |       9999      |
|  **SRV_CN**  | www.example.com |
| **SRV_ORG**  |    My Company   |
| **SRV_DAYS** |       9999      |

### Running examples

Start an instance out of the box with username `test` and password `test`

```bash
docker run --name ocserv --privileged -p 443:443 -p 443:443/udp -d registry.cn-hangzhou.aliyuncs.com/sourcegarden/ocserv-fp:v1.7
```

Start an instance with server name `my.test.com`, `My Test` and `365` days

```bash
docker run --name ocserv --privileged -p 443:443 -p 443:443/udp -e SRV_CN=my.test.com -e SRV_ORG="My Test" -e SRV_DAYS=365 -d registry.cn-hangzhou.aliyuncs.com/sourcegarden/ocserv-fp:v1.7
```

Start an instance with CA name `My CA`, `My Corp` and `3650` days

```bash
docker run --name ocserv --privileged -p 443:443 -p 443:443/udp -e CA_CN="My CA" -e CA_ORG="My Corp" -e CA_DAYS=3650 -d registry.cn-hangzhou.aliyuncs.com/sourcegarden/ocserv-fp:v1.7
```

A totally customized instance with both CA and server certification

```bash
docker run --name ocserv --privileged -p 443:443 -p 443:443/udp -e CA_CN="My CA" -e CA_ORG="My Corp" -e CA_DAYS=3650 -e SRV_CN=my.test.com -e SRV_ORG="My Test" -e SRV_DAYS=365 -d registry.cn-hangzhou.aliyuncs.com/sourcegarden/ocserv-fp:v1.7
```

Start an instance as above but without test user

```bash
docker run --name ocserv --privileged -p 443:443 -p 443:443/udp -e CA_CN="My CA" -e CA_ORG="My Corp" -e CA_DAYS=3650 -e SRV_CN=my.test.com -e SRV_ORG="My Test" -e SRV_DAYS=365 -e NO_TEST_USER=1 -v /some/path/to/ocpasswd:/etc/ocserv/ocpasswd -d registry.cn-hangzhou.aliyuncs.com/sourcegarden/ocserv-fp:v1.7
```

**WARNING:** The ocserv requires the ocpasswd file to start, if `NO_TEST_USER=1` is provided, there will be no ocpasswd created, which will stop the container immediately after start it. You must specific a ocpasswd file pointed to `/etc/ocserv/ocpasswd` by using the volume argument `-v` by docker as demonstrated above.

### User operations

All the users opertaions happened while the container is running. If you used a different container name other than `ocserv`, then you have to change the container name accordingly.

#### Add user

If say, you want to create a user named `tommy`, type the following command

```bash
docker exec -ti ocserv ocpasswd -c /etc/ocserv/ocpasswd -g "Route,All" tommy
Enter password:
Re-enter password:
```

When prompt for password, type the password twice, then you will have the user with the password you want.

>`-g "Route,ALL"` means add user `tommy` to group `Route` and group `All`

#### Delete user

Delete user is similar to add user, just add another argument `-d` to the command line

```bash
docker exec -ti ocserv ocpasswd -c /etc/ocserv/ocpasswd -d test
```

The above command will delete the default user `test`, if you start the instance without using environment variable `NO_TEST_USER`.

#### Change password

Change password is exactly the same command as add user, please refer to the command mentioned above.
