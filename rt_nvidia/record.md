# Nvidia Install Preempt-RT methods
## 1. Install by Command line
### modify source configure
```
$ sudo vi /etc/apt/sources.list.d/nvidia-l4t-apt-source.list
```
### Add RT repository
```
deb https://repo.download.nvidia.com/jetson/rt-kernel <release> main
# Note that <release> be like r36.3
```

### Update
```
$ sudo apt update
```

### Install RT kernel Package
* For Jetson Thor devices:
```
$ sudo apt install nvidia-l4t-rt-kernel nvidia-l4t-rt-kernel-headers nvidia-l4t-rt-kernel-oot-modules nvidia-l4t-display-rt-kernel nvidia-l4t-rt-kernel-openrm
```

* For Jetson Orin devices:
```
$ sudo apt install nvidia-l4t-rt-kernel nvidia-l4t-rt-kernel-headers nvidia-l4t-rt-kernel-oot-modules nvidia-l4t-display-rt-kernel nvidia-l4t-rt-kernel-nvgpu
```

### Reboot

### Note for remove RT kernel
* For Jetson Thor devices:
```
$ sudo apt remove nvidia-l4t-rt-kernel nvidia-l4t-rt-kernel-headers nvidia-l4t-rt-kernel-oot-modules nvidia-l4t-display-rt-kernel nvidia-l4t-rt-kernel-openrm
```

* For Jetson Orin devices:
```
$ sudo apt remove nvidia-l4t-rt-kernel nvidia-l4t-rt-kernel-headers nvidia-l4t-rt-kernel-oot-modules nvidia-l4t-display-rt-kernel nvidia-l4t-rt-kernel-nvgpu
```

* Reboot

### Switch Boot Kernel 
* modify the config file '/boot/extlinux/extlinux.conf'
```
TIMEOUT 30
DEFAULT real-time
#DEFAULT primary
```


## 2. Install by Cross-compile

### Dowload Driver Source


### Download toolchain
* NVidia thor => x-tools

### Decompress files
```
tar jxvf public_sources.tbz2
cd Linux_for_Tegra/source/
tar jxvf kernel_src.tbz2
cd kernel/kernel_noble
```

### Build Kernel
* Set Env
```
export ARCH=arm64
export CROSS_COMPILE=$HOME/nv/AFE-R750/x-tools/aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
```

* Confirm GCC Version
```
${CROSS_COMPILE}gcc --version
```

* Set thor defconfig
```
make tegra_prod_defconfig
```

* [Option] Enable RT-kernel
```
Enable:
General setup --->
  (*) Configure standard kernel features (expert users)
  
  Preemption Model
    (X) Fully Preemptible Kernel (Real-Time)

  Timer subsystem --->
    CONFIG_NO_HZ_FULL
  RCU subsystem --->
    CONFIG_RCU_NOCB_CPU
```



# Kernel Tuning
* Kernel Build
```
Build the kernel with CONFIG_NO_HZ_FULL=y and CONFIG_RCU_NOCB_CPU=y.
```

* Kernel Boot parameter
1. Remove efi=runtime from the kernel boot parameters.

2. Add the following to the kernel boot parameters. Here, CPUs 8–13 are isolated for the real-time application; adjust based on your application:

```
rcu_nocb_poll rcu_nocbs=8-13 nohz=on nohz_full=8-13 kthread_cpus=0,1,2,3,4,5,6,7 irqaffinity=0,1,2,3,4,5,6,7 isolcpus=managed_irq,domain,8-13
Run the following commands:
```

3. Disable real-time task CPU time throttling:
```
sudo sysctl kernel.sched_rt_runtime_us=-1
echo -1 | sudo tee /proc/sys/kernel/sched_rt_runtime_us
```

4. Disable real-time CPU runtime throttling:
```
sudo sysctl kernel.timer_migration=0
echo 0 | sudo tee /proc/sys/kernel/timer_migration
```

# Reference link
1. https://docs.nvidia.com/jetson/archives/r38.2.1/DeveloperGuide/SD/Kernel/RealTimeKernel.html

