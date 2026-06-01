#!/bin/bash

# 檢查 root 權限
if [ "$EUID" -ne 0 ]; then
  echo "請使用 sudo 執行此腳本！"
  exit 1
fi

EFI_GUID="12345678-abcd-ef01-2345-6789abcdef01"
VAR_NAME="MyCustomVar"
FILEPATH="/sys/firmware/efi/efivars/${VAR_NAME}-${EFI_GUID}"

# 同 C++ 定義的金鑰與 IV (轉為無換行純十六進位)
KEY_HEX=$(echo -n "0123456789abcdef0123456789abcdef" | xxd -p | tr -d '\n ')
IV_HEX=$(echo -n "abcdef0123456789" | xxd -p | tr -d '\n ')

if [ ! -f "$FILEPATH" ]; then
    echo "錯誤：找不到 EFI 節點 ${FILEPATH}"
    exit 1
fi

echo "--- 1. 讀取並解密 EFI 變數 ---"

# 【關鍵修正】bs=1 skip=4 跳過屬性頭，count=32 嚴格唯讀取 32 位元組的 AES 密文區塊
DECRYPTED_STR=$(dd if="$FILEPATH" bs=1 skip=4 count=32 2>/dev/null | openssl enc -d -aes-256-cbc -K "$KEY_HEX" -iv "$IV_HEX" 2>/dev/null)

if [ -z "$DECRYPTED_STR" ]; then
    echo "解密失敗！可能金鑰錯誤或資料損毀。"
    exit 1
else
    echo "取得源字串: ${DECRYPTED_STR}"
fi

echo "--- 2. 刪除 EFI 檔案節點 ---"
chattr -i "$FILEPATH" 2>/dev/null
rm -f "$FILEPATH"

if [ ! -f "$FILEPATH" ]; then
    echo "成功從 NVRAM 中刪除該 EFI 變數節點！"
else
    echo "刪除失敗，請檢查權限或硬體狀態。"
fi