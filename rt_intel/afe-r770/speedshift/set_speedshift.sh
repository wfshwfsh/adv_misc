#!/bin/bash

# check bios setting

# check grub param

# set CPU core_n: performance mode, desired, max, min freq

#sudo wrmsr 0x774 -p 0 0xf000000080001601

core_n=$1
echo "core_n: $core_n"

if [ -n "$core_n" ]; then
	state=$(sudo rdmsr 0x774 -p "$core_n")
else
        echo "Error: invalid input core_n."
        exit 1
fi

# 將讀取到的 16 進位字串轉為數值
val=$((16#$state))

# 解析低 32 位元各欄位 (Bits 0-23 為 Performance Ratios, Bits 24-31 為 EPP)
min_perf=$(( val & 0xFF ))
max_perf=$(( (val >> 8) & 0xFF ))
des_perf=$(( (val >> 16) & 0xFF ))
epp=$(( (val >> 24) & 0xFF ))

# 換算為約略頻率 (cal as *10 *1.27 MHz for P-core; *10*1.0 for E-core)
min_freq=$(awk -v perf="$min_perf" 'BEGIN { printf "%.2f", perf / 13.75 }')
des_freq=$(awk -v perf="$des_perf" 'BEGIN { printf "%.2f", perf / 13.75 }')
max_freq=$(awk -v perf="$max_perf" 'BEGIN { printf "%.2f", perf / 13.75 }')

echo "Raw State: 0x$state"
echo "----------------------------------------"
echo "Min Perf Ratio     : $min_perf (${min_freq} GHz)"
echo "Desired Perf Ratio : $des_perf ($([ "$des_perf" -eq 0 ] && echo "Autonomous/Auto" || echo "${des_freq} GHz"))"
echo "Max Perf Ratio     : $max_perf ($([ "$max_perf" -eq 0 ] && echo "Max Turbo (No Limit)" || echo "${max_freq} GHz"))"
echo "EPP Value          : $epp (0x$(printf '%02x' "$epp"))"
echo "----------------------------------------"


### SET
des_ratio=$max_perf
max_ratio=$max_perf
#min_ratio=$min_perf
min_ratio=$max_perf
epp_performance=0x00

target_val=$(printf "0xf0000000%02x%02x%02x%02x" "$epp_performance" "$des_ratio" "$max_ratio" "$min_ratio")
#target_val=$(printf "0x00000000%02x%02x%02x%02x" "$epp_performance" "$des_ratio" "$max_ratio" "$min_ratio")
echo "Generated MSR Value: $target_val"
sudo wrmsr 0x774 -p $core_n $target_val

