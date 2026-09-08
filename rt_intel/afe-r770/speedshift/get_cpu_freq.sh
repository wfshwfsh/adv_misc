#!/bin/bash

core_n=$1
BACKUP_FILE="${2:-hwp_backup.conf}"

# 確認 Speed Shift 是否啟用
state_speedshift=$(sudo rdmsr 0x770)
if [[ $state_speedshift -eq 1 ]]; then
    echo "Speed Shift: ON"
else
    echo "Speed Shift: OFF. Operation aborted."
    exit 0
fi

if [ -z "$core_n" ]; then
    echo "Usage: $0 <core_id|all> [backup_file]"
    exit 1
fi

# 清空或建立備份檔案
> "$BACKUP_FILE"

echo "Backing up core(s) to $BACKUP_FILE..."

if [ "$core_n" == "all" ]; then
    total_cores=$(nproc)
    for ((i=0; i<total_cores; i++)); do
        state=$(sudo rdmsr 0x774 -p "$i")
        echo "$i 0x$state" >> "$BACKUP_FILE"
        echo "CPU[$i] -> 0x$state"
    done
elif [[ "$core_n" =~ ^[0-9]+$ ]]; then
    state=$(sudo rdmsr 0x774 -p "$core_n")
    echo "$core_n 0x$state" >> "$BACKUP_FILE"
    echo "CPU[$core_n] -> 0x$state"
else
    echo "Error: invalid input core_n '$core_n'."
    exit 1
fi

echo "Backup completed: $BACKUP_FILE"

