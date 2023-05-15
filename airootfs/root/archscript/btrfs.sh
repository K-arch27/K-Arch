#!/bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG_FILE=/root/archscript/config.sh
source $SCRIPT_DIR/config.sh


if [ -d /sys/firmware/efi ]; then
  firmtype="UEFI"
  set_option FIRMWARE_TYPE $firmtype
else
  firmtype="BIOS"
  set_option FIRMWARE_TYPE $firmtype
fi

function partition_check {
    # Prompt the user with a clickable option to check if they are ready
    zenity --question --text="Are your partitions ready?" --ok-label="Yes" --cancel-label="No"
    if [ $? -eq 1 ]; then
         zenity --info --text="Close Gparted When Done"
        # Launch GParted and wait for it to close
        gparted &
        while pgrep gparted >/dev/null; do sleep 1; done
    fi
}


function swappartition() {
    
    # Ask user if they have a Swap partition
    if zenity --question --text="Do you have a Swap partition?"; then
    set_option SWAPPART "yes"
        swappartition2
    else
        set_option SWAPPART "no"
        zenity --info --text="No Swap partition will be used." 2>/dev/null
    fi
}




function swappartition2() {

        # Ask user to select Swap partition
        # Create a list of options using available partitions
        options=()
        for partition in $partitions; do
            options+=("$partition")
        done
        partition4=$(zenity --list --title="Select SWAP partition" --text="Please select your SWAP partition:" --column "Partitions" "${options[@]}" 2>/dev/null)
            
            if zenity --question --text="Your Swap is ${partition4}. Is this correct?" --title="Confirmation" 2>/dev/null ; then
                set_option SWAPPART "$partition4"
                mkswap "$partition4"
                uuid4=$(blkid -o value -s UUID "$partition4")
                set_option SWAPUUID "$uuid4"
            else   
                swappartition
            fi
            
            if [[ -z "$partition4" ]]; then
                zenity --error --text "No partition selected."
                swappartition
            fi
}



function homefinal () {
clear
logo
set_option HOMEPART "yes"
set_option HOMESNAP "no"
uuid5=$(blkid -o value -s UUID $partition5)
set_option HOMEUUID $uuid5
}





function homeformat() {
    # Ask user if they want Btrfs or Ext4 for Home
    if zenity --question --text="Do you want to format Home with Btrfs? Click 'Yes' for Btrfs, 'No' for Ext4."; then
        mkfs.btrfs -L HOME -m single -f "$partition5"
        homefinal
    else
        mkfs.ext4 -L HOME "$partition5"
        homefinal
    fi
}



function homepartition2() {
   

    # Create a list of options using available partitions
    options=()
    for partition in $partitions; do
        options+=("$partition")
    done

        # Ask user to choose a partition
        partition5=$(zenity --list --title "Choose Home Partition" --text "Choose a Home partition to use:" --column "Partitions" "${options[@]}" 2>/dev/null)
        if [[ -z "$partition5" ]]; then
            zenity --error --text "No partition selected."
            return 1
        fi

      # Ask user whether to format Home or not
      if zenity --question --text "Do you want to format Home?"; then
          homeformat
      else
          homefinal
      fi

    
}



function homesnapchoice() {
    # Ask user whether to include /Home in snapshot
        if zenity --question --title "Home Snapshot Choice" --text "Do you want /Home to be included inside snapshot?\nBe aware that doing so might result in lost data when rolling the system back to a previous state."; then
        homesnap="yes"
        else
        homesnap="no"
        fi

    set_option HOMESNAP $homesnap
}



function homepartition() {
    # Ask user if they want a separate Home partition
    if zenity --question --text "Do you want a separate Home partition? (Doing so prevents Home from being included in a snapshot)"; then
      homepartition2
    else
        # If user chooses No, set HOMEPART to "no" and call homesnapchoice function
        set_option HOMEPART "no"
        homesnapchoice
    fi
}

function efiformat () {

    # choice for formatting the EFI partition
    if zenity --question --text="Do you want to format the EFI partition ${partition2}?\nChoose 'No' if it's already used by another system or 'Yes' if it's a new partition."; then
        zenity --warning --text "EFI partition will be formatted."
        mkfs.vfat -F32 ${partition2}
        uuid2=$(blkid -o value -s UUID $partition2)
        set_option EFIUUID $uuid2
    else
        zenity --warning --text="Please make sure it's a valid EFI partition, otherwise the following may fail.Click 'OK' to resume."
    fi
}

function efipartition() {
   

    # Create a list of options using available partitions
    options=()
    for partition in $partitions; do
        options+=("$partition")
    done

    # Ask user to choose a partition
    partition2=$(zenity --list --title "Choose EFI Partition" --text "Choose an EFI partition to use:" --column "Partitions" "${options[@]}" 2>/dev/null)
    if [[ -z "$partition2" ]]; then
        zenity --error --text "No partition selected."
        efipartition
    fi

    # Set the selected partition as the value of the EFIPART option
    set_option EFIPART "$partition2"
}



function rootpartition() {

    # Create a list of options using available partitions
    options=()
    for partition in $partitions; do
        options+=("$partition")
    done

    # Ask user to choose a partition
    partition3=$(zenity --list --title "Choose Root Partition" --text "Choose a Root partition to use:" --column "Partitions" "${options[@]}" 2>/dev/null)
    if [[ -z "$partition3" ]]; then
        zenity --error --text "No partition selected."
        roorpartition
    fi

    set_option ROOTPART "$partition3"
    mkfs.btrfs -L ROOT -m single -f $partition3
    uuid3=$(blkid -o value -s UUID $partition3)
    set_option ROOTUUID $uuid3
}

    #Executing this script functions

    partition_check
    partitions=$(lsblk -rno NAME,TYPE,SIZE | awk '$2 == "part" && $1 !~ /^(sr0|loop)/ {split($1,a,""); if (a[length(a)] ~ /[0-9]/) print $1}')
    clear
    if [ FIRMWARE_TYPE = "UEFI" ]; then
    lsblk
    efipartition
    efiformat
    uuid2=$(blkid -o value -s UUID $partition2)
    set_option EFIUUID $uuid2
    fi
    clear
    lsblk
    swappartition
    clear
    lsblk
    homepartition
    clear
    lsblk
    rootpartition
    
    
