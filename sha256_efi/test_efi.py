
# 範例：建立一個名為 MyTestVar 的變數，內容為 "Hello"
# 屬性 0x07 (NV+BS+RT) 在小端序 (Little Endian) 為 \x07\x00\x00\x00
header = b'\x07\x00\x00\x00'
data = b'Hello2'

with open('/sys/firmware/efi/efivars/MyTestVar-12345678-1234-1234-1234-1234567890ab', 'wb') as f:
    f.write(header + data)
