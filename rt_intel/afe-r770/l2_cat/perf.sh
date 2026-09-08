#event=0xd1,umask=0x02：L2 Hit（命中了 L2）
#event=0xd1,umask=0x10：L2 Miss（L2 沒抓到，必須送往 L3/LLC 或主記憶體）

#L2 All Count = L2 Hit 數 + L2 Miss 數
#L2 Miss Rate = L2 Miss / (L2 Hit + L2 Miss)

sudo perf stat -C 7 -e cpu_atom/event=0xd1,umask=0x02/ -e cpu_atom/event=0xd1,umask=0x10/ -I 1000
