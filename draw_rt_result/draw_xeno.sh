#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 latency.log"
    exit 1
fi

LOG=$1
DATA=lat_raw.dat
HIST=lat_hist.dat

echo "[1] Extract max latency..."
grep "^RTD" "$LOG" | awk -F"|" '{print $4+0}' > $DATA

MAX=$(awk 'BEGIN{max=0} {if($1>max) max=$1} END{print max}' $DATA)
echo "Max latency: $MAX us"

echo "[2] Generate 0~100us histogram..."
awk '
BEGIN { for(i=0;i<=100;i++) hist[i]=0 }
{
    v=int($1)
    if(v<0) v=0
    if(v>=0 && v<=100) hist[v]++
}
END {
    for(i=0;i<=100;i++) print i, hist[i]
}' $DATA > $HIST

echo "[3] Plot histogram with gnuplot (log Y-axis, Max label)..."
gnuplot <<EOF
set terminal pngcairo size 1500,800 enhanced font 'Arial,14'
set output "latency_hist_max.png"
set title "Xenomai Latency Distribution (Max Latency per Cycle)"
set xlabel "Latency (us)"
set ylabel "Count"
set xrange [0:*]
set yrange [1:*]
set logscale y 10
set ytics (10,100,1000,10000)
set style fill empty
set boxwidth 0.8
set style line 1 lt 1 lw 2 lc rgb "purple"

# 在圖內加 Max latency 文字，使用 graph 座標，不會被 logscale 壓掉
set label 1 sprintf("Max Latency = %.3f (us)", $MAX) at graph 0.95, graph 0.95 front tc rgb "red" right

plot "$HIST" using 1:2 with boxes ls 1 title "count"
EOF

echo "Generated: latency_hist_max.png"
echo "Histogram data: $HIST"
echo "Raw max latency list: $DATA"

