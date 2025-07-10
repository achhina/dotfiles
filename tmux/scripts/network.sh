#!/bin/bash
# Get network rates by sampling twice with 1 second interval
line1=$(/usr/sbin/netstat -b -I en0 | tail -1)
ibytes1=$(echo "$line1" | awk '{print $7}')
obytes1=$(echo "$line1" | awk '{print $10}')

sleep 1

line2=$(/usr/sbin/netstat -b -I en0 | tail -1)
ibytes2=$(echo "$line2" | awk '{print $7}')
obytes2=$(echo "$line2" | awk '{print $10}')

# Calculate rates (bytes per second)
irate=$((ibytes2 - ibytes1))
orate=$((obytes2 - obytes1))

# Format output with fixed width (always show KB/s or higher)
if [ $irate -ge 1000000 ]; then
    down=$(printf "%4.1fM/s" "$(echo "scale=1; $irate/1000000" | bc)")
else
    down=$(printf "%4.0fK/s" $((irate/1024)))
fi

if [ $orate -ge 1000000 ]; then
    up=$(printf "%4.1fM/s" "$(echo "scale=1; $orate/1000000" | bc)")
else
    up=$(printf "%4.0fK/s" $((orate/1024)))
fi

printf "%s ↓ %s ↑" "$down" "$up"
