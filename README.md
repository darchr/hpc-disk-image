# Packer scripts for building HPC disk images

## Status

|               | rv64gc | arm64 | arm64sve |
| ------------- | ------ | ----- | -------- |
| stream        |     ✔ |    ✔ |       ✔ |
| gups          |     ❌ |    ❌ |       ❌ |
| spatter       |     ✔ |    ✔ |       ✔ |
| npb           |     ✔ |    ✔ |       ✔ |
| point-chasing |     ❌ |    ❌ |       ❌ |

## Download Packer

See [https://developer.hashicorp.com/packer/downloads](https://developer.hashicorp.com/packer/downloads).

## Building the rv64gc Disk Image

### Downloading the Pre-installed RISC-V Disk Image

We chose this disk image because the disk image is known to work with QEMU.

See [https://ubuntu.com/download/risc-v](https://ubuntu.com/download/risc-v).

```sh
wget https://cdimage.ubuntu.com/releases/22.04.2/release/ubuntu-22.04.2-preinstalled-server-riscv64+unmatched.img.xz
xz dk ubuntu-22.04.2-preinstalled-server-riscv64+unmatched.img.xz
mv ubuntu-22.04.2-preinstalled-server-riscv64+unmatched.img rv64gc-hpc-2204.img
qemu-img resize rv64gc-hpc-2204.img +20G
```

### Launching a QEMU Instance

```sh
qemu-system-riscv64 -machine virt -nographic \
     -m 16384 -smp 8 \
     -bios /usr/lib/riscv64-linux-gnu/opensbi/generic/fw_jump.elf \
     -kernel /usr/lib/u-boot/qemu-riscv64_smode/uboot.elf \
     -device virtio-net-device,netdev=eth0 \
     -netdev user,id=eth0,hostfwd=tcp::5555-:22 \
     -drive file=rv64gc-hpc-2204.img,format=raw,if=virtio
```

### Running the Packer Script

While the QEMU Instance is running,

```sh
./packer build rv64gc-hpc.json
```

## Building the arm64 Disk Image

### Downloading the arm64 Cloud Disk Image

See [https://cloud-images.ubuntu.com/](https://cloud-images.ubuntu.com/).

```sh
wget https://cloud-images.ubuntu.com/jammy/20230418/jammy-server-cloudimg-arm64.img
qemu-img convert jammy-server-cloudimg-arm64.img -O raw ./arm64-hpc-2204.img
qemu-img resize arm64-hpc-2204.img +20G
```

### Setting up an SSH key pair

The default key path is `~/.ssh/id_rsa` might overwrite a current key.
You can change the key path, and make a corresponding change in
`arm64-hpc.json`.

```sh
ssh-keygen -C "ubuntu@localhost"
ssh-add ~/.ssh/id_rsa
```

### Launching a QEMU Instance

```sh
dd if=/dev/zero of=flash0.img bs=1M count=64
dd if=/usr/share/qemu-efi/QEMU_EFI.fd of=flash0.img conv=notrunc
dd if=/dev/zero of=flash1.img bs=1M count=64
qemu-system-aarch64 -m 16384 -smp 8 -cpu cortex-a57 -M virt \
    -nographic -pflash flash0.img -pflash flash1.img \
    -drive if=none,file=aarch64-ubuntu.img,id=hd0 -device virtio-blk-device,drive=hd0 \
    -drive if=none,id=cloud,file=cloud.img,format=raw -device virtio-blk-device,drive=cloud \
    -netdev user,id=user0 -device virtio-net-device,netdev=eth0 \
    -netdev user,id=eth0,hostfwd=tcp::5555-:22
```

### Running the Packer Script

While the QEMU Instance is running,

```sh
./packer build arm64-hpc.json
```