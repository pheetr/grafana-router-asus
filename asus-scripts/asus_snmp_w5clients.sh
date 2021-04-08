#!/bin/ash

# Number of 5GHz wireless clients connected
wl -i eth7 assoclist | wc -l