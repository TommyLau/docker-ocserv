#!/usr/bin/env python
# -*- coding: utf-8 -*-

import socket
import xml.etree.ElementTree
import urllib2


def get_netmask(mask):
    bits = 0
    for i in xrange(32 - mask, 32):
        bits |= (1 << i)
    return "%d.%d.%d.%d" % ((bits & 0xff000000) >> 24, (bits & 0xff0000) >> 16, (bits & 0xff00) >> 8, (bits & 0xff))


def get_decimal_ip(ip):
    ip_split = ip.split('.')
    ip_decimal = 0

    for i in ip_split:
        ip_decimal += int(i)
        ip_decimal <<= 8

    ip_decimal >>= 8
    return ip_decimal


def query_cidr(ip):
    url = "http://whois.arin.net/rest/nets;q=%s?showDetails=true&showARIN=false&ext=netref2" % ip
    f = urllib2.urlopen(url)
    ss = f.read()
    root = xml.etree.ElementTree.fromstring(ss)
    net_block = root.find("{http://www.arin.net/whoisrws/core/v1}net").find(
        "{http://www.arin.net/whoisrws/core/v1}netBlocks").find("{http://www.arin.net/whoisrws/core/v1}netBlock")
    start_address = net_block.find("{http://www.arin.net/whoisrws/core/v1}startAddress").text
    cidr_length = int(net_block.find("{http://www.arin.net/whoisrws/core/v1}cidrLength").text)
    return start_address, get_netmask(cidr_length)


if __name__ == "__main__":
    route_table = {}

    with open("domains.txt", "r") as f:
        for line in f:
            domain = line.strip()

            if len(domain) != 0 and domain[0] != '#':
                print("Processing domain [%s] " % domain),
                ip = socket.gethostbyname(domain)
                print("IP: %s" % ip),
                decimal_ip = get_decimal_ip(ip)
                exist = False
                for t in route_table:
                    if (get_decimal_ip(route_table[t][1]) & decimal_ip) == t:
                        exist = True
                        break
                if exist:
                    print "exist, skip . . ."
                else:
                    addr, mask = query_cidr(ip)
                    route_table[get_decimal_ip(addr)] = (addr, mask)
                    print("CIDR: %s/%s" % (addr, mask))

    tables = sorted(route_table.items())

    with open("route.txt", "w") as f:
        for route in tables:
            print("route = %s/%s" % (route[1][0], route[1][1]))
            f.write("route = %s/%s\n" % (route[1][0], route[1][1]))
