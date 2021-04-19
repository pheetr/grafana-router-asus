#!/bin/ash

# Wireless Temperature command with calculations performed (eth6: 2.4GHz, eth7: 5GHz)
wl -i eth6 phy_tempsense | awk '{print $1 / 2 + 20}'