#!/usr/bin/env bash
# CPU usage % sampled over ~0.3s from /proc/stat.
read -r _ a b c d e f g h _ < /proc/stat
t1=$((a + b + c + d + e + f + g + h))
i1=$d
sleep 0.3
read -r _ a b c d e f g h _ < /proc/stat
t2=$((a + b + c + d + e + f + g + h))
i2=$d
dt=$((t2 - t1))
di=$((i2 - i1))
if [ "$dt" -le 0 ]; then
    echo 0
else
    echo $(((100 * (dt - di)) / dt))
fi
