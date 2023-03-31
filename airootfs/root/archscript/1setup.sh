#!/usr/bin/env bash

#!/bin/bash

function partition_check {
    # Prompt the user with a clickable option to check if they are ready
    zenity --question --text="Are your partitions ready?" --ok-label="Yes" --cancel-label="No"
    if [ $? -eq 1 ]; then
        # Launch GParted and wait for it to close
        gparted &
        while pgrep gparted >/dev/null; do sleep 1; done
    fi
}


    partition_check
    # Check for available partitions
    partitions=$(lsblk -o NAME,SIZE -p -n -l -d | grep -vE "/|^\s*loop" | awk '{print $1}')

    # If no partitions are found, return error
    if [[ -z "$partitions" ]]; then
        zenity --error --text "No available partitions found."
        return 1
    fi
    
# This script will ask users about their prefrences
# like timezone, keyboard layout,
# user name, password, etc.


    pacman-key --init
    pacman-key --populate archlinux
    pacman -Sy archlinux-keyring --needed --noconfirm
    sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
    
    #Might have to resort to using this if I can't figure out chaotic-aur signing consistently
    #sed -i 's/^SigLevel    = Required DatabaseOptional/SigLevel    = Never/' /etc/pacman.conf

    pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
    pacman-key --lsign-key FBA220DFC880C036
    pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
    cat $SCRIPT_DIR/mirror.txt >> /etc/pacman.conf
    pacman -Sy  chaotic-keyring --needed --noconfirm
    pacman -S --noconfirm --needed btrfs-progs gptfdisk reflector rsync glibc
    timedatectl set-ntp true
    echo -ne "
-------------------------------------------------------------------------
                    Updating Mirrorlist
-------------------------------------------------------------------------
"
    reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

    clear

# set up a config file
CONFIG_FILE=/root/archscript/config.sh
source /root/archscript/config.sh


function timezone() {
  # Added this from arch wiki https://wiki.archlinux.org/title/System_time
  timezone="$(curl --fail https://ipapi.co/timezone)"

  # Zenity prompt to confirm detected timezone
  if zenity --question --text="System detected your timezone to be '$timezone'. Is this correct?" --title="Timezone Detection"; then
    zenity --info --text="${timezone} set as timezone." --title="Timezone Set"
    setopt TIMEZONE $timezone
  else
    while true; do
      new_timezone=$(zenity --entry --text="Please enter your desired timezone e.g. Europe/London:" --title="Timezone Selection")

      # Verify that the timezone entered is valid
      if tzselect <<< "$new_timezone" >/dev/null 2>&1; then
        zenity --info --text="${new_timezone} set as timezone." --title="Timezone Set"
        setopt TIMEZONE $new_timezone
        break
      else
        zenity --error --text="Invalid timezone entered. Please try again." --title="Timezone Selection Error"
      fi
    done
  fi
}


function localeselect() {
  # Get a list of available locales
  options=($(locale -a))

  # Zenity prompt to select locale
  locale=$(zenity --list --text="Please select your locale from this list:" --title="Locale Selection" --column="Locale" "${options[@]}")

  # Zenity prompt to confirm selected locale
  if zenity --question --text="Your locale: ${locale}. Is this correct?" --title="Locale Confirmation"; then
    set_option LANGLOCAL $locale
  else
    while true; do
      locale=$(zenity --list --text="Please choose your locale again:" --title="Locale Selection" --column="Locale" "${options[@]}")
      if zenity --question --text="Your locale: ${locale}. Is this correct?" --title="Locale Confirmation"; then
        set_option LANGLOCAL $locale
        break
      else
        zenity --error --text="Please choose your locale again." --title="Locale Selection Error"
      fi
    done
  fi
}


function keymap() {
  # These are default key maps as presented in official arch repo archinstall
  options=(by ca cf cz de dk es et fa fi fr gr hu il it lt lv mk nl no pl ro ru sg ua uk us)

  # Zenity prompt to select keymap
  keymap=$(zenity --list --text="Please select your keyboard layout from this list:" --title="Keymap Selection" --column="Keymap" "${options[@]}")

  # Zenity prompt to confirm selected keymap
  zenity --question --text="Your keyboard layout: ${keymap}. Is this correct?" --title="Keymap Confirmation"

  # Check user response and set keymap accordingly
  if [ $? = 0 ]; then
    set_option KEYMAP $keymap
    loadkeys $keymap
  else
    while true; do
      keymap=$(zenity --list --text="Please choose your keyboard layout again:" --title="Keymap Selection" --column="Keymap" "${options[@]}")
      zenity --question --text="Your keyboard layout: ${keymap}. Is this correct?" --title="Keymap Confirmation"
      if [ $? = 0 ]; then
        set_option KEYMAP $keymap
        loadkeys $keymap
        break
      else
        zenity --error --text="Please choose your keyboard layout again." --title="Keymap Selection Error"
      fi
    done
  fi
}


function loginshell() {
    # Define available options
    options=("bash" "fish" "zsh")

    # Display Zenity dialog to select an option
    shellchoice=$(zenity --list --title="Select Login Shell" --text="Select Your login shell (root will still use bash)" --column="Shell" "${options[@]}")

    # Check if the user confirmed the selection
    confirmed=$(zenity --question \
        --title="Confirm Login Shell" \
        --text="Your shell: ${shellchoice}\n Is this correct?")

    # Handle user's confirmation
    if [[ $confirmed == "True" ]]; then
        set_option SHELLCHOICE $shellchoice
    else
        loginshell
    fi
}




function kernelselect () {
  # Prompt user to select a kernel
  options=(linux linux-zen linux-hardened linux-lts)
  kernelchoice=$(zenity --list --text "Please select a kernel from this list" --title "Kernel Selection" --column "Kernel" "${options[@]}")

  # Prompt user to confirm selected kernel
  zenity --question --text "Your kernel: ${kernelchoice}. Is this correct?" --title "Kernel Confirmation"

  # Check user response and set kernel accordingly
  if [ $? = 0 ]; then
    set_option KERNELCHOICE $kernelchoice
  else
    while true; do
      kernelchoice=$(zenity --list --text "Please choose your kernel again:" --title "Kernel Selection" --column "Kernel" "${options[@]}")
      zenity --question --text "Your kernel: ${kernelchoice}. Is this correct?" --title "Kernel Confirmation"
      if [ $? = 0 ]; then
        set_option KERNELCHOICE $kernelchoice
        break
      else
        zenity --error --text "Please choose your kernel again." --title "Kernel Selection Error"
      fi
    done
  fi
}


function lib32repo () {
  libchoice=$(zenity --list --text "Do you want the Multilib repo?" --column "Options" "yes" "no")

  zenity --question --text="Your choice: $libchoice\nIs this correct?" --ok-label="Yes" --cancel-label="No"
  response=$?
  
  case $response in
    0)
      set_option LIBCHOICE $libchoice;;
    1)
      clear
      echo "Please choose again"
      lib32repo;;
    *)
      echo "Wrong option. Try again"
      lib32repo;;
  esac
}


function AurHelper () {
    aurchoice=$(zenity --list --title="AUR Helper" --text="Please select an aur helper from this list" --column="Options" "none" "yay" "paru" "octopi-paru" "octopi-yay")
    
    zenity --question --title="Confirm" --text="Your choice : ${aurchoice}\nIs this correct?"
    
    if [[ $? -eq 0 ]]; then
        set_option AURCHOICE $aurchoice
    else
        zenity --warning --title="Wrong option" --text="Wrong option. Try again"
        AurHelper
    fi
}


function chaorepo () {
    chaochoice=$(zenity --list --title="Chaotic-Aur Repo" --text="Do you want the Chaotic-Aur repo ?" --column="Options" "no" "yes")
    
    zenity --question --title="Confirm" --text="Your choice : ${chaochoice}\nIs this correct?"
    
    if [[ $? -eq 0 ]]; then
        set_option CHAOCHOICE $chaochoice
    else
        zenity --warning --title="Wrong option" --text="Wrong option. Try again"
        chaorepo
    fi
}


function blackarch () {
    blackchoice=$(zenity --list --title="BlackArch Repo" --text="Do you want the BlackArch repo ?" --column="Options" "no" "yes")
    
    zenity --question --title="Confirm" --text="Your choice : ${blackchoice}\nIs this correct?"
    
    if [[ $? -eq 0 ]]; then
        set_option BLACKCHOICE $blackchoice
    else
        zenity --warning --title="Wrong option" --text="Wrong option. Try again"
        blackarch
    fi
}


}


function userinfo () {

while true; do
  username=$(zenity --entry --text="Enter the text:" 2>/dev/null)
  if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    echo "Invalid username. Usernames must start with a letter or underscore, and only contain letters, digits, hyphens, and underscores."
  else
    break
  fi
done

while true; do

password=$(zenity --password --title "Enter Root Password" --hide-text 2>/dev/null)
password2=$(zenity --password --title "Repeat Root Password" --hide-text 2>/dev/null)

  if [ "$password" = "$password2" ]; then
    hashed_password=$(echo "$password" | sha256sum | awk '{print $1}')
    break
  else
    echo -e "\nPasswords do not match. Please try again. \n"
  fi
done

while true; do

rootpassword=$(zenity --password --title "Enter Root Password" --hide-text 2>/dev/null)
rootpassword2=$(zenity --password --title "Repeat Root Password" --hide-text 2>/dev/null)


  if [ "$rootpassword" = "$rootpassword2" ]; then
    hashed_rootpassword=$(echo "$rootpassword" | sha256sum | awk '{print $1}')
    break
  else
    echo -e "\nPasswords do not match. Please try again. \n"
  fi
done

set_option USERNAME "${username}"
set_option PASSWORD "${hashed_password}"
set_option ROOTPASSWORD "${hashed_rootpassword}"
}


function myhostname() {
  while true; do
    hostname=$(zenity --entry --text="Please enter your hostname:" --title="Hostname" 2>/dev/null)
    if [ -z "$hostname" ]; then
      zenity --error --text="Hostname cannot be empty." --title="Error" 2>/dev/null
    else
      break
    fi
  done

  zenity --question --text="Your hostname is ${hostname}. Is this correct?" --title="Confirmation" 2>/dev/null

  if [ $? -eq 0 ]; then
    set_option NAME_OF_MACHINE "$hostname"
  else
    myhostname
  fi
}



function efiformat () {

    # choice for formatting the EFI partition
    if zenity --question --text="Do you want to format the EFI partition ${partition2}?\nChoose 'No' if it's already used by another system or 'Yes' if it's a new partition."; then
        echo "EFI partition will be formatted."
        mkfs.vfat -F32 ${partition2}
        uuid2=$(blkid -o value -s UUID $partition2)
        set_option EFIUUID $uuid2
    else
        if zenity --question --text="Please make sure it's a valid EFI partition, otherwise the following may fail.\nClick 'OK' to resume."; then
            uuid2=$(blkid -o value -s UUID $partition2)
            set_option EFIUUID $uuid2
            return 0
        else
            efiformat
        fi
    fi
}


function swappartition() {
    

    # Create a list of options using available partitions
    options=()
    for partition in $partitions; do
        options+=("$partition")
    done

    # Ask user to choose a partition
    choice=$(zenity --list --text="Do you have a Swap partition?" --radiolist --column "Select" --column "Option" \
    TRUE "Yes" \
    FALSE "No" "${options[@]}" 2>/dev/null)
    
    case $choice in
    "Yes")
        # Ask user to select Swap partition
        partition4=$(zenity --list --title="Select SWAP partition" --text="Please select your SWAP partition:" --column "Partitions" "${options[@]}" 2>/dev/null)
        if [[ -z "$partition4" ]]; then
            zenity --error --text "No partition selected."
            return 1
        fi

        set_option SWAPPART "$partition4"
        mkswap "$partition4"
        uuid4=$(blkid -o value -s UUID "$partition4")
        set_option SWAPUUID "$uuid4";;
    "No")
        zenity --info --text="No Swap partition will be used." 2>/dev/null;;
    *)
        zenity --error --text="Invalid option. Please try again." 2>/dev/null
        zen_swappartition;;
    esac
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
    # Choice for Home Filesystem
    choice=$(zenity --list \
        --title="Home Filesystem" \
        --text="Do you want Btrfs or Ext4 for Home?" \
        --column="Filesystem" "Btrfs" "Ext4" \
        --width=250 --height=150 --hide-header --hide-scrollbar 2>/dev/null)

    case $choice in
        "Btrfs")
            mkfs.btrfs -L HOME -m single -f "$partition5"
            homefinal
            ;;
        "Ext4")
            mkfs.ext4 -L HOME "$partition5"
            homefinal
            ;;
        *)
            echo "Wrong option. Try again"
            homeformat
            ;;
    esac
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
    zenity --question --text "Do you want to format Home?"
    if [[ $? -eq 0 ]]; then
        # If user chooses to format, ask for filesystem type
        zenity --question --text "Do you want Btrfs or Ext4 for Home?"
        if [[ $? -eq 0 ]]; then
            # If user chooses Btrfs, format with Btrfs
            mkfs.btrfs -L HOME -m single -f ${partition5}
            homefinal
        else
            # If user chooses Ext4, format with Ext4
            mkfs.ext4 -L HOME ${partition5}
            homefinal
        fi
    else
        # If user chooses not to format, use partition as is
        echo "Home Partition is gonna be used as is"
        read -p "Press any key to resume"
        homefinal
    fi
}


function homesnapchoice() {
    # Ask user whether to include /Home in snapshot
    zenity --question --title "Home Snapshot Choice" --text "Do you want /Home to be included inside snapshot?\nBe aware that doing so might result in lost data when rolling the system back to a previous state."
    if [[ $? -eq 0 ]]; then
        homesnap="yes"
    else
        homesnap="no"
    fi

    set_option HOMESNAP $homesnap
}


function homepartition() {
    # Ask user if they want a separate Home partition
    zenity --question --text "Do you want a separate Home partition? (Doing so prevents Home from being included in a snapshot)"
    if [[ $? -eq 0 ]]; then
        # If user chooses Yes, call the homepartition2 function
        homepartition2
    else
        # If user chooses No, set HOMEPART to "no" and call homesnapchoice function
        set_option HOMEPART "no"
        homesnapchoice
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
        return 1
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
        return 1
    fi

    set_option ROOTPART "$partition3"
    mkfs.btrfs -L ROOT -m single -f $partition3
    uuid3=$(blkid -o value -s UUID $partition3)
    set_option ROOTUUID $uuid3
}


    clear
    logo
    keymap
    clear
    logo
    userinfo
    clear
    logo
    myhostname
    clear
    logo
    timezone
    clear
    logo
    localeselect
    clear
    logo
    lsblk
    efipartition
    clear
    logo
    efiformat
    clear
    logo
    swappartition
    clear
    logo
    lsblk
    homepartition
    clear
    logo
    lsblk
    rootpartition
    clear
    clear
    logo
    loginshell
    clear
    logo
    desktopenv
    clear
    logo
    kernelselect
    clear
    logo
    lib32repo
    clear
    logo
    AurHelper
    clear
    logo
    chaorepo
    clear
    logo
    blackarch
