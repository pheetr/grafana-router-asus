#!/bin/ash

# Number of running processes
ps | wc -l | awk '{print $1 - 1}'