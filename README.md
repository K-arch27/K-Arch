# K-Arch

## My own Config for ArchIso Installing Arch with Btrfs

### This Config has been modified to allow users to easily install Arch Linux with a Btrfs file system as the root file system, and with pre-configured subvolume ready for use with the Snapper tool.


### -- Build yourself --

1. Install archiso (https://archlinux.org/packages/extra/any/archiso/)
2. Clone this repo
3. Use mkarchiso inside the repo to build the iso

### -- Important Note --

- 50Gb Device minimum for Automatic partitionning (Otherwise you need to make an EFI(if needed) and Root partition minimally yourself)

- If using the layout only those modification need to be done at the end of your install : 

>sed -i 's/rootflags=subvol=${rootsubvol}//' /etc/grub.d/10_linux

>sed -i 's/rootflags=subvol=${rootsubvol}//' /etc/grub.d/20_linux_xen

>sed -i 's|,subvolid=258,subvol=/@/.snapshots/1/snapshot| |' /etc/fstab

To make subvolume are not hardcoded into grub and fstab, so the default subvolume is used instead (and can be changed at will)

### -- Features --

- Live Environement Booting Xfce

- Prompt the User If they want to Use the Full Install script with customized options or just the btrfs layout script for manual install

- Installer can partition a device for you (50Gb Min.) Or you can choose to manually make your partitions for the install ( Swap and Home are optionnal )

- Gparted Included for ease of partitionning

- Firefox Included if you need to consult the Arch Wiki

- Auto-Installer custom options per user choices (Keymap, Locale, Username, Hostname, Kernel, Shell, Graphical Environement, Choice of Repo, Aur Helper)

- Possibility to add package of your choice during install (If pacman find them in the repo)

- A btrfs layout working with snapper out of the box

![image](https://user-images.githubusercontent.com/98610690/229260800-4bc7d45d-16f6-472e-81d8-92bae0d2e08b.png)



- Bootable snapshot for easy rollback after booting them ( snapper rollback && grub-mkconfig -o /boot/grub/grub.cfg )

![image](https://user-images.githubusercontent.com/98610690/229261491-301400e0-7d50-4367-854f-f6c55053f999.png)

![image](https://user-images.githubusercontent.com/98610690/229261473-8563a715-a87c-4350-8cb2-2bc03ca40819.png)



### -- To do --

~~Make it work with Bios~~ Done !

~~Add auto-Partitionning for single Drive~~ Done ! ( will add more customisation to this latter tho.)

add luks encryption option

Add More helpful prompt

Make it nicer looking

more ..?
