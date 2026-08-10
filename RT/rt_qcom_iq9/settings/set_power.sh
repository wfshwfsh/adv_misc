#!/bin/bash


# Set CPU in performance
for policy in /sys/devices/system/cpu/cpufreq/policy*;
do
   if [ -w "$policy/scaling_governor" ];
then
      echo performance > "$policy/scaling_governor"
   fi
done

