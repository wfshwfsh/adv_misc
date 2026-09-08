#!/bin/bash

if [ "$1" -eq 1 ]; then
    # 1. 切割 Core 2 的 L2 Cache (總長度 10 bits: 0x3ff)
    # CLOS 0 (一般核心): 0x01f (低 5 bits)
    # CLOS 1 (RT 核心) : 0x3e0 (高 5 bits)
    sudo wrmsr -p3 0xd10 0x01f
    sudo wrmsr -p3 0xd11 0x3e0

    # 2. 將 Core 2 綁定至 CLOS 1 (bit 32 = 1)
    sudo wrmsr -p3 0xc8f 0x100000000
    echo "Core 2 L2 CAT 隔離啟用完成 (CLOS 1: 0x3e0)"
else
    # 1. 將所有核心的 CLOS ID 還原為 CLOS 0
    sudo wrmsr 0xc8f 0x0 -a

    # 2. 還原 Core 2 的 L2 Cache 為全滿狀態 (10 bits: 0x3ff)
    sudo wrmsr -p3 0xd10 0x3ff
    sudo wrmsr -p3 0xd11 0x3ff
    echo "L2 CAT 已重置為預設狀態 (0x3ff)"
fi
