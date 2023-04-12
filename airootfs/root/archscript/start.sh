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
    chmod +x /root/archscript/startup.sh
    chmod +x /root/archscript/btrfs.sh
    chmod +x /root/archscript/1setup.sh
    chmod +x /root/archscript/2partition.sh
    chmod +x /root/archscript/3strap.sh
    chmod +x /root/archscript/4chroot.sh
    chmod +x /root/archscript/5final.sh

function StartingUp {
   
   
   
# Display Zenity dialog box with three buttons
zenity --question --title="Choose an option" --text="Select an option:" \
       --ok-label="Install Arch Linux" --cancel-label="Use the Btrfs Layout Tool only" --extra-button="Close For Now"

# Capture the exit status of the dialog box
result=$?

# Check exit status and take appropriate action
case $result in
    0)
        # Action for Option 1 (OK button)
    ( bash /root/archscript/startup.sh )|& tee /root/archscript/startup.log
    zenity --info --title="Done" --text="You can now reboot or use chroot and customize your system" --ok-label="OK"
    exit
        ;;
    1)
        # Action for Option 2 (Cancel button)
    ( bash /root/archscript/btrfs.sh )|& tee /root/archscript/btrfs.log
    ( bash /root/archscript/2partition.sh )|& tee /root/archscript/partition.log
    zenity --info --title="Done" --text="You can now proceed with a normal manual install" --ok-label="OK"
    exit
        ;;
    2)
        # Action for Option 3 (Extra button)
        echo "Option 3 selected"
        zenity --info --title="When Ready" --text="You can Launch Back the install / Layout tool by right clicking the desktop" --ok-label="OK"
        exit
        ;;
    *)
        # No or invalid choice
        exit
        ;;
esac

}


StartingUp
