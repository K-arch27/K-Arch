# K-Arch

## My own Config for ArchIso Installing Arch with Btrfs

### This Config has been modified to allow users to easily install Arch Linux with a Btrfs file system as the root file system, and with a pre-configured subvolume ready for use with the Snapper tool.


### -- Build yourself --

1. Install archiso
2. Clone this repo
3. Use mkarchiso inside the repo to build the iso

### -- Important Note --

If using the layout only those modification need to be done at the end of your install : 

#make subvolumes not be hardcoded in grub & fstab making bootable snaps and rollback easy to manage

sed -i 's/rootflags=subvol=${rootsubvol}//' /etc/grub.d/10_linux

sed -i 's/rootflags=subvol=${rootsubvol}//' /etc/grub.d/20_linux_xen

sed -i 's|,subvolid=258,subvol=/@/.snapshots/1/snapshot| |' /etc/fstab


### -- Features --

- Installer only work for UEFI for now (make sure to have an Efi partition and a Root partition , the rest is optionnal)

- Live Environement Booting Xfce


- Prompt the User If they want to Use the Install script or just the Tool to make the btrfs layout and make everything ready for a manual install


- Gparted Included for ease of partitionning


- Firefox Included so the user can make some search on the different options


- Auto-Installer that prompt the User with some choice about the system they want (Keymap, Locale, Username, Hostname, Kernel, Shell, Graphical Environement, Choice of Repo, Aur Helper, etc..)  variation of my script found there : https://github.com/K-arch27/archscript


- Possibility to add package of your choice during install


- A btrfs layout working with snapper out of the box

![image](https://user-images.githubusercontent.com/98610690/229260800-4bc7d45d-16f6-472e-81d8-92bae0d2e08b.png)



- Bootable snapshot

![image](https://user-images.githubusercontent.com/98610690/229261491-301400e0-7d50-4367-854f-f6c55053f999.png)

![image](https://user-images.githubusercontent.com/98610690/229261473-8563a715-a87c-4350-8cb2-2bc03ca40819.png)



### -- To do --

~~Make it work with Bios~~

Add auto-Partitionning for single Drive

add luks encryption option

Make it nicer looking

more ..?
