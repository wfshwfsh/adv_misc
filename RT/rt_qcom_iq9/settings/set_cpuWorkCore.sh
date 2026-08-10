#!/bin/bash

# Affine kernel worqueue to housekeeping cpus
for wq in /sys/devices/virtual/workqueue/*; do
   if [ -w "$wq/cpumask" ]; then
      echo 7F > "$wq/cpumask"
   fi
done


