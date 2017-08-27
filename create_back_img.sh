#!/bin/sh

#下载软件包
apt-get install -y \
        dosfstools \
        dump \
        parted \
        kpartx /

#新建空白磁盘
sudo dd if=/dev/zero of=lede_back.img bs=1MB count=500

#分区
sudo parted lede_back.img --script -- mklabel msdos
sudo parted lede_back.img --script -- mkpart primary fat32 8192s 90111s
sudo parted lede_back.img --script -- mkpart primary ext4 90112s -1

#挂载虚拟磁盘并且格式化
loopdevice=`sudo losetup -f --show lede_back.img`
device=`sudo kpartx -va $loopdevice | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
device="/dev/mapper/${device}"
partBoot="${device}p1"
partRoot="${device}p2"

#格式化
sudo mkfs.vfat $partBoot
sudo mkfs.ext4 $partRoot

#建立虚拟磁盘挂载点
mkdir vroot vboot
#挂载
sudo mount -t vfat $partBoot vboot

#备份，/boot为sd卡的启动文件目录
sudo cp -rfp /boot/* vboot/

#卸载
sudo umount vboot
#删除临时挂载点
rm -rf vboot

#挂载
sudo mount -t ext4 $partRoot vroot
cd ./vroot

#备份，root为sd卡挂载的根目录
sudo dump -0uaf - root | sudo restore -rf -

#返回上一层
cd ..
sudo umount vroot

#卸载虚拟磁盘
sudo kpartx -d $loopdevice
sudo losetup -d $loopdevice
