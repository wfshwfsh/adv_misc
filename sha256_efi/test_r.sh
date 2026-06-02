#!/bin/bash

# 檢查 root 權限
if [ "$EUID" -ne 0 ]; then
  echo "Permission Deny, try with 'sudo'"
  exit 1
fi

EFI_GUID="12345678-abcd-ef01-2345-6789abcdef01"
VAR_NAME="ImageManager"
FILEPATH="/sys/firmware/efi/efivars/${VAR_NAME}-${EFI_GUID}"

# Sync to C++, define key & IV (trans to pure hex, with no 'enter')
KEY_HEX=$(echo -n "0123456789abcdef0123456789abcdef" | xxd -p | tr -d '\n ')
IV_HEX=$(echo -n "abcdef0123456789" | xxd -p | tr -d '\n ')

if [ ! -f "$FILEPATH" ]; then
    echo "Failed to find efi node ${FILEPATH}"
    exit 1
fi

echo "--- 1. 讀取並解密 EFI 變數 ---"

# 【關鍵修正】bs=1 skip=4 escape attr, count=32: strictly ro 32bytes AES block
DECRYPTED_STR=$(dd if="$FILEPATH" bs=1 skip=4 count=32 2>/dev/null | openssl enc -d -aes-256-cbc -K "$KEY_HEX" -iv "$IV_HEX" 2>/dev/null)

if [ -z "$DECRYPTED_STR" ]; then
    echo "Decrypt failed, wrong key or broken data"
    exit 1
else
    echo "Get data string: ${DECRYPTED_STR}"
fi

echo "--- 2. Remove EFI node ---"
chattr -i "$FILEPATH" 2>/dev/null
rm -f "$FILEPATH"

if [ ! -f "$FILEPATH" ]; then
    echo "Remove EFI node success"
else
    echo "Failed to Remove EFI node"
fi
