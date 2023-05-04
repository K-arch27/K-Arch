#!/bin/bash


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
    source /root/archscript/config.sh
    chmod +x /root/archscript/btrfs.sh
    chmod +x /root/archscript/1setup.sh
    chmod +x /root/archscript/2partition.sh
    chmod +x /root/archscript/3strap.sh
    chmod +x /root/archscript/4chroot.sh

function StartingUp {
    # Define the options for the dropdown list
    options=("Install Arch Linux" "Use the Btrfs Layout Tool only" "Close For Now")

    # Display Zenity dialog box with a dropdown list
    selected_option=$(zenity --list --title="Choose an option" --text="Select an option:" \
                           --column="Options" "${options[@]}")

    # Check the selected option and take appropriate action
    case "$selected_option" in
        "Install Arch Linux")
        
            # Action for Option 1 (Install Arch Linux)
   source /root/archscript/config.sh
    ( bash /root/archscript/1setup.sh )|& tee /root/archscript/setup.log
    ( bash /root/archscript/2partition.sh )|& tee /root/archscript/partition.log
    ( bash /root/archscript/3strap.sh )|& tee /root/archscript/strap.log
    ( arch-chroot /mnt /root/archscript/4chroot.sh )|& tee /mnt/root/archscript/chroot.log
    
 zenity --info --title="Done !" --text="You can Now Reboot or Arch-Chroot to /mnt to set more things up manually" --ok-label="OK"
            ;;
        "Use the Btrfs Layout Tool only")
            # Action for Option 2 (Use the Btrfs Layout Tool only)
            
           ( bash /root/archscript/btrfs.sh )|& tee /root/archscript/btrfs.log
           ( bash /root/archscript/2partition.sh )|& tee /root/archscript/partition.log
            zenity --info --title="Done !" --text="You can Now start a Manual Arch Install by pacstraping to /mnt" --ok-label="OK"
            ;;
        "Close For Now")
            # Action for Option 3 (Close For Now)
            zenity --info --title="When Ready" --text="You can Launch Back the script on the desktop" --ok-label="OK"
            exit
            ;;
        *)
            # No or invalid choice
            exit
            ;;
    esac
}



StartingUp
