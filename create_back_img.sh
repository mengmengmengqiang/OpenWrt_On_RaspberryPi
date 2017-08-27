#!/bin/sh

#因为是对磁盘操作，所以适当的延迟。

#下载软件包
apt-get install -y \
        dosfstools \
        dump \
        parted \
        kpartx

#新建空白磁盘
sudo dd if=/dev/zero of=lede.img bs=1MB count=500

sleep 3s
#分区
sudo parted lede.img --script -- mklabel msdos
sleep 1s
sudo parted lede.img --script -- mkpart primary fat32 8192s 90111s
sleep 1s
sudo parted lede.img --script -- mkpart primary ext4 90112s -1

sleep 1s
#挂载虚拟磁盘并且格式化
loopdevice=`sudo losetup -f --show lede.img`
device=`sudo kpartx -va $loopdevice | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
device="/dev/mapper/${device}"
partBoot="${device}p1"
partRoot="${device}p2"

sleep 1s
#格式化
sudo mkfs.vfat $partBoot
sleep 2s
sudo mkfs.ext4 $partRoot

#建立虚拟磁盘挂载点
mkdir vroot vboot

#挂载
sudo mount -t vfat $partBoot vboot
sleep 3s
#备份，/boot为sd卡的启动文件目录
sudo cp -rfp /media/renqiang/boot/* vboot/

sleep 3s
#卸载
sudo umount vboot
#删除临时挂载点
rm -rf vboot

#挂载
sudo mount -t ext4 $partRoot vroot
sleep 3s
cd ./vroot

#备份，root为sd卡挂载的根目录
sudo dump -0uaf - /media/renqiang/root | sudo restore -rf -
sleep 3s
#返回上一层
cd ..
sudo umount vroot
rm -rf vroot

#卸载虚拟磁盘
sudo kpartx -d $loopdevice
sudo losetup -d $loopdevice
