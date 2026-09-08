#!/bin/bash
#watch -n1 'cat /sys/devices/virtual/thermal/*/temp; lscpu -e'

LOGFILE="thermal_cpu.log"

while true; do
    echo "==================== $(date '+%Y-%m-%d %H:%M:%S') ====================" >> "$LOGFILE"

    echo "--- Thermal Temps (mC) ---" >> "$LOGFILE"
    # 逐一列出 sensor 名稱與溫度 (毫攝氏度，除以 1000 即為度C)
    for t in /sys/devices/virtual/thermal/thermal_zone*/temp; do
        [ -f "$t" ] && echo "$t: $(cat "$t")" >> "$LOGFILE"
    done

    echo "--- lscpu -e ---" >> "$LOGFILE"
    lscpu -e >> "$LOGFILE"

    echo "" >> "$LOGFILE"
    sleep 1
done
