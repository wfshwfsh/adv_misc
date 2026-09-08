#跑在core 1上, -C是針對cache作壓力測試
sudo stress-ng -t0 -C 0 --taskset 6
