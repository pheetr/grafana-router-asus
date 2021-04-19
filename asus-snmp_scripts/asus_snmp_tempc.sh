#!/bin/ash

# CPU Temperature with mC->C calculation performed
cat /sys/class/thermal/thermal_zone0/temp | awk '{print $1 / 1000}'