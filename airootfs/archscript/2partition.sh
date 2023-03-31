#!/usr/bin/env bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/config.sh


    mount UUID=${ROOTUUID} /mnt


    btrfs subvolume create /mnt/@
	btrfs subvolume create /mnt/@/.snapshots
	mkdir /mnt/@/.snapshots/1
	btrfs subvolume create /mnt/@/.snapshots/1/snapshot
	mkdir /mnt/@/boot
	btrfs subvolume create /mnt/@/boot/grub
	btrfs subvolume create /mnt/@/root
	btrfs subvolume create /mnt/@/srv
	btrfs subvolume create /mnt/@/tmp
	
	if [ "$HOMEPART" = "no" ] && [ "$HOMESNAP" = "no" ]; then
   
   	btrfs subvolume create /mnt/@/home
   
	fi 
	
	mkdir /mnt/@/var
	btrfs subvolume create /mnt/@/var/cache
	btrfs subvolume create /mnt/@/var/log
	btrfs subvolume create /mnt/@/var/spool
	btrfs subvolume create /mnt/@/var/tmp
	NOW=$(date +"%Y-%m-%d %H:%M:%S")
	sed -i "s|2022-01-01 00:00:00|${NOW}|" info.xml
	cp info.xml /mnt/@/.snapshots/1/info.xml
  	btrfs subvolume set-default $(btrfs subvolume list /mnt | grep "@/.snapshots/1/snapshot" | grep -oP '(?<=ID )[0-9]+') /mnt
	btrfs quota enable /mnt
	chattr +C /mnt/@/var/cache
	chattr +C /mnt/@/var/log
	chattr +C /mnt/@/var/spool
	chattr +C /mnt/@/var/tmp

# unmount root to remount with subvolume
    umount /mnt

# mount @ subvolume
    mount UUID=${ROOTUUID} -o compress=zstd /mnt

# make directories home, .snapshots, var, tmp

	mkdir /mnt/.snapshots
	mkdir -p /mnt/boot/grub
	mkdir /mnt/root
	mkdir /mnt/tmp
	mkdir -p /mnt/var/cache
	mkdir /mnt/var/log
	mkdir /mnt/var/spool
	mkdir /mnt/var/tmp
	mkdir /mnt/boot/efi
    	mkdir /mnt/home

# mount subvolumes and partition

    mount UUID=${ROOTUUID} -o noatime,compress=zstd,ssd,commit=120,subvol=@/.snapshots /mnt/.snapshots
    mount UUID=${ROOTUUID} -o noatime,compress=zstd,ssd,commit=120,subvol=@/boot/grub /mnt/boot/grub
    mount UUID=${ROOTUUID} -o noatime,compress=zstd,ssd,commit=120,subvol=@/root /mnt/root
    mount UUID=${ROOTUUID} -o noatime,compress=zstd,ssd,commit=120,subvol=@/tmp /mnt/tmp
    mount UUID=${ROOTUUID} -o noatime,ssd,commit=120,subvol=@/var/cache /mnt/var/cache
    mount UUID=${ROOTUUID} -o noatime,ssd,commit=120,subvol=@/var/log,nodatacow /mnt/var/log
    mount UUID=${ROOTUUID} -o noatime,ssd,commit=120,subvol=@/var/spool,nodatacow /mnt/var/spool
    mount UUID=${ROOTUUID} -o noatime,ssd,commit=120,subvol=@/var/tmp,nodatacow /mnt/var/tmp
    mount UUID=${EFIUUID} /mnt/boot/efi
    swapon UUID=${SWAPUUID}
    
   if [ "$HOMEPART" = "yes" ] && [ "$HOMESNAP" = "no" ]; then
   
    mount UUID=${HOMEUUID} /mnt/home/

   fi 
	
 if [ "$HOMEPART" = "no" ] && [ "$HOMESNAP" = "no" ]; then
   
    mount UUID=${ROOTUUID} -o noatime,compress=zstd,ssd,commit=120,subvol=@/home /mnt/home

   fi 


