#!/bin/ash

# Connections active
cat /proc/net/nf_conntrack | grep -i -c -E "(tcp.*established)|(udp.*assured)"