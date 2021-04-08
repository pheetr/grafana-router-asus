#!/bin/ash

# % of JFFS partition used (47MB total on RT-AX86U)
df | grep "jffs" | awk '{print $5 - "%"}'