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
    # Define the options for the dropdown list
    options=("Install Arch Linux" "Use the Btrfs Layout Tool only" "Close For Now")

    # Display Zenity dialog box with a dropdown list
    selected_option=$(zenity --list --title="Choose an option" --text="Select an option:" \
                           --column="Options" "${options[@]}")

    # Check the selected option and take appropriate action
    case "$selected_option" in
        "Install Arch Linux")
            # Action for Option 1 (Install Arch Linux)
            konsole --noclose -e /root/archscript/startup.sh &
            exit
            ;;
        "Use the Btrfs Layout Tool only")
            # Action for Option 2 (Use the Btrfs Layout Tool only)
            konsole --noclose -e /root/archscript/btrfs.sh &
            exit
            ;;
        "Close For Now")
            # Action for Option 3 (Close For Now)
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
