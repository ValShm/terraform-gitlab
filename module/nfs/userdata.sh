#!/bin/bash
set -x

echo "Updating"
sudo apt-get update
sleep 10

DEVICE=$(lsblk  --noheadings --raw | awk '{print substr($0,0,4)}' | uniq -c | grep 1 | awk '{print "/dev/"$2}')
FS_TYPE=$(file -s $DEVICE | awk '{print $2}')
MOUNT_POINT=/gitlab-nfs

echo "If no FS, then this output contains data"
if [ "$FS_TYPE" = "data" ]
then
    echo "Creating file system on $DEVICE"
    sudo mkfs -t ext4 $DEVICE
fi

mkdir $MOUNT_POINT
sudo mount $DEVICE $MOUNT_POINT

sudo apt-get install -y nfs-kernel-server
sudo chmod 777 /etc/exports /etc/hosts.allow /gitlab-nfs

echo "$MOUNT_POINT *(rw,no_root_squash)" >>  /etc/exports
echo "rspbind = ALL
portmap = ALL
nfs = ALL" >> /etc/hosts.allow

sudo chmod 755 /etc/exports /etc/hosts.allow
sudo /etc/init.d/nfs-kernel-server restart
sudo showmount -e