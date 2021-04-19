#!/bin/ash

# Active SSH connections
netstat -tnp | grep -c 'ESTABLISHED.*dropbear'