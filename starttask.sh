#!/bin/bash

NVMEMOUNT=/mnt/nvme
SSDMOUNT=/mnt/resource
beeondmount=/mnt/beeond

# NVME disk setup for BeeOND data (HBv2)
if [ -e /dev/nvme0n1 ]; then
	fdisk /dev/nvme0n1 << EOF
n
p
1


w
EOF
	mkfs.ext4 /dev/nvme0n1
	mkdir $NVMEMOUNT
	mount /dev/nvme0n1 $NVMEMOUNT
	beeonddata=$NVMEMOUNT/beeond
else
	beeonddata=$SSDMOUNT/beeond # using local SSD disk (/mnt/resource) for BeeOND data (HB/HC)
fi

# BeeOND setup
## Create BeeOND directories
mkdir $beeonddata
chmod 777 $beeonddata
mkdir $beeondmount
chmod 777 $beeondmount

## Install
wget -O /etc/yum.repos.d/beegfs-rhel7.repo https://www.beegfs.io/release/beegfs_7_1/dists/beegfs-rhel7.repo
rpm --import https://www.beegfs.io/release/latest-stable/gpg/RPM-GPG-KEY-beegfs
yum install -y epel-release
yum install -y psmisc libbeegfs-ib beeond pdsh htop

## Rebuild BeeOND client for RDMA communication
sed -i 's/^buildArgs=-j8/buildArgs=-j8 BEEGFS_OPENTK_IBVERBS=1 OFED_INCLUDE_PATH=\/usr\/src\/ofa_kernel\/default\/include/g' /etc/beegfs/beegfs-client-autobuild.conf
/etc/init.d/beegfs-client rebuild
/etc/init.d/beegfs-client restart

## Enable RDMA communication for root user
cp -rv /home/_azbatch/.ssh /root/.
sed -i 's/home\/_azbatch/root/g' /root/.ssh/config
chmod 700 /root/.ssh
chmod 644 /root/.ssh/config
chmod 644 /root/.ssh/authorized_keys

## Enable sudo for _azbatch
echo "_azbatch ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/azbatch
echo "Defaults:_azbatch !requiretty" >> /etc/sudoers.d/azbatch

# IOR setup
if [ -f ior.tgz ]; then 
	tar zxf ior.tgz -C /opt
fi
