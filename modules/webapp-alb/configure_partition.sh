#!/usr/bin/env bash

device_name=/dev/xvdz
disk_name=logs

parted ${device_name} mklabel gpt --script
parted ${device_name} mkpart primary 0% 100% --script
parted ${device_name} name 1 ${disk_name} --script

# mkfs errors out otherwise
sleep 2
mkfs.ext4 /dev/disk/by-partlabel/${disk_name}

cat >> /etc/fstab << EOM
PARTLABEL=${disk_name}  /var/log    ext4    defaults    0   2
EOM

mount /var/log
