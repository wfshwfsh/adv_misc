#!/bin/bash

BACKUP_FILE="${1:-hwp_backup.conf}"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file '$BACKUP_FILE' not found."
    exit 1
fi

# 確認 Speed Shift 是否啟用
state_speedshift=$(sudo rdmsr 0x770)
if [[ $state_speedshift -ne 1 ]]; then
    echo "Warning: Speed Shift is OFF. Enabling or verifying state may be required."
fi

echo "Restoring HWP settings from $BACKUP_FILE..."

# 逐行讀取 CPU ID 與對應的 MSR 數值
while read -r cpu_id msr_val; do
    # 忽略空行或註解行
    [[ -z "$cpu_id" || "$cpu_id" =~ ^# ]] && continue

    echo "Restoring CPU[$cpu_id] with value $msr_val..."
    sudo wrmsr 0x774 "$msr_val" -p "$cpu_id"
done < "$BACKUP_FILE"

echo "Restore completed successfully."
