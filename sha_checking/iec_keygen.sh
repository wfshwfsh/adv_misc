#!/bin/bash

PATH_PLATFORM_STR="/sys/firmware/efi/efivars/BIOSString-aaaa0056-3341-44b5-9c9c-6d76f76738bb"
PATH_IEC_KEY="/usr/local/Advantech/PowerSuite/IecCode.key"

PLATFORM_STR=$(cat $PATH_PLATFORM_STR)
_part=${PLATFORM_STR#**** }
platform_name=${_part%% BIOS*}
echo "platform_name: $platform_name"

#platform_name="ARK-3530"

# 取得字元
first_char="${platform_name:0:1}"
third_char="${platform_name:2:1}"
last_char="${platform_name: -1}"

# 構造 salt（順序為：最後字元、第一字元、第3字元）
salt="${last_char}${first_char}${third_char}"

# 合併 platform_name 和 salt
input="${platform_name}${salt}"

# 計算 SHA256 並轉大寫
sha256=$(echo -n "$input" | sha256sum | awk '{print toupper($1)}')

# 輸出結果
echo "Platform Name: $platform_name"
echo "Salt: $salt"
echo "Combined: $input"
echo "SHA256: $sha256"

# Produce key to specific path
#sudo echo "$sha256" > $PATH_IEC_KEY

