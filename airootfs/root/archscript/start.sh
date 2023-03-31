#!/usr/bin/env bash
clear
echo -ne "
-------------------------------------------------------------------------
                 █████╗ ██████╗  ██████╗██╗  ██╗
                ██╔══██╗██╔══██╗██╔════╝██║  ██║
                ███████║██████╔╝██║     ███████║
                ██╔══██║██╔══██╗██║     ██╔══██║
                ██║  ██║██║  ██║╚██████╗██║  ██║
                ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
-------------------------------------------------------------------------
        Automated Arch Linux Installer With Btrfs Snapshot
-------------------------------------------------------------------------

"
    chmod +x /root/archscript/1setup.sh
    chmod +x /root/archscript/2partition.sh
    chmod +x /root/archscript/3strap.sh
    chmod +x /root/archscript/4chroot.sh
    chmod +x /root/archscript/5final.sh
    source /root/archscript/config.sh
    ( bash /root/archscript/1setup.sh )|& tee /root/archscript/setup.log
    ( bash /root/archscript/2partition.sh )|& tee /root/archscript/partition.log
    ( bash /root/archscript/3strap.sh )|& tee /root/archscript/strap.log
    ( arch-chroot /mnt /root/archscript/4chroot.sh )|& tee /mnt/root/archscript/chroot.log
    ( arch-chroot /mnt /root/archscript/5final.sh )|& tee /mnt/root/archscript/final.log
   
echo -ne "
-------------------------------------------------------------------------
                 █████╗ ██████╗  ██████╗██╗  ██╗
                ██╔══██╗██╔══██╗██╔════╝██║  ██║
                ███████║██████╔╝██║     ███████║
                ██╔══██║██╔══██╗██║     ██╔══██║
                ██║  ██║██║  ██║╚██████╗██║  ██║
                ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
-------------------------------------------------------------------------
        Automated Arch Linux Installer With Btrfs Snapshot
-------------------------------------------------------------------------
            Done - Please Eject Install Media and Reboot
      Also note that this script copied itself in /root/archscript/
             with the config you choosed and the logs

"
