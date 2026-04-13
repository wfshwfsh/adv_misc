#define _GNU_SOURCE
#include <stdio.h>
#include <cpuid.h>
#include <sched.h>
#include <unistd.h>

// 定義核心類型常數
#define CORE_TYPE_E_CORE 0x20
#define CORE_TYPE_P_CORE 0x40

int get_cpu_core_type() {
    unsigned int eax, ebx, ecx, edx;
    // 呼叫 CPUID leaf 0x1A
    // EAX = 0x1A 時，傳回值 EAX 的高 8 位元 (24-31 bits) 代表核心類型
    if (__get_cpuid_count(0x1a, 0, &eax, &ebx, &ecx, &edx)) {
        return (eax >> 24) & 0xFF;
    }
    return 0; // 不支援混合架構偵測
}

int main() {
    int num_cpus = sysconf(_SC_NPROCESSORS_CONF);
    printf("系統偵測到 %d 個邏輯核心\n", num_cpus);
    printf("正在掃描 P-cores...\n\n");

    cpu_set_t original_mask;
    sched_getaffinity(0, sizeof(cpu_set_t), &original_mask);

    for (int i = 0; i < num_cpus; i++) {
        cpu_set_t mask;
        CPU_ZERO(&mask);
        CPU_SET(i, &mask);

        // 將當前執行緒暫時綁定到目標核心，以便讀取該核心的 CPUID
        if (sched_setaffinity(0, sizeof(cpu_set_t), &mask) == 0) {
            // 給予微小延遲確保切換完成（選用）
            usleep(100); 

            int type = get_cpu_core_type();
            
            if (type == CORE_TYPE_P_CORE) {
                printf("[CPU %2d] 類型: P-core (Performance)\n", i);
            } else if (type == CORE_TYPE_E_CORE) {
                printf("[CPU %2d] 類型: E-core (Efficiency)\n", i);
            } else {
                printf("[CPU %2d] 類型: 未知/不支援\n", i);
            }
        }
    }

    // 還原原本的 affinity
    sched_setaffinity(0, sizeof(cpu_set_t), &original_mask);

    return 0;
}
