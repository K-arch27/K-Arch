#!/bin/bash

# set up a config file
CONFIG_FILE=/root/archscript/config.sh
source /root/archscript/config.sh

if [ -d /sys/firmware/efi ]; then
  firmtype="UEFI"
  set_option FIRMWARE_TYPE $firmtype
else
  firmtype="BIOS"
  set_option FIRMWARE_TYPE $firmtype
fi


function auto_part () {
    # Prompt the user to check if they want auto partitionning
    if zenity --question --text="Do you want the script to Erase and Partition a Device for you ?" --ok-label="Yes" --cancel-label="No"; then
      autoPart="yes"
       if zenity --question --text="Do you Want a Swap partition ?"; then
          autoSwap="yes"
          set_option SWAPON $autoSwap
          else
          autoSwap="no"
          set_option SWAPON $autoSwap
       fi
       #Home partition or not
       if zenity --question --text="Do you Want a Separate Home partition ?"; then
          set_option HOMEPART "yes"
          set_option HOMESNAP "no"
          autoHome="yes"
          #Btrfs or Ext4 for Home
          if zenity --question --text="What Filesystem do you want for /home ?" --ok-label="Btrfs" --cancel-label="Ext4"; then
             autoHomeFs="btrfs"
          else
              autoHomeFs="ext4"
          fi
       else
          set_option HOMEPART "no"
          autoHome="no"
          if zenity --question --text="Do you Want Home Included in Snapshots ? ?"; then
            autoSnapHome="yes"
            set_option HOMESNAP $autoSnapHome
            else
            autoSnapHome="no"
            set_option HOMESNAP $autoSnapHome
          fi
       fi
      auto_part2   
    else
    autoPart="no"
    fi
}



function auto_part2 () {

devices=$(lsblk -rndo NAME)
options=()
for device in $devices; do
    if [[ $device != "sr0" && $device != "loop0" ]]; then
        options+=("$device")
    fi
done

 #choose a device to partition
selected_device=$(zenity --list --title="Select Device" --text="Please select your device:" --column "Devices" "${options[@]}" 2>/dev/null)
selected_device="/dev/$selected_device"

while [ ! -e "$selected_device" ]; do
  if [ -z "$selected_device" ]; then
    zenity --error --text="No device selected. Please select a valid device."
  else
    zenity --error --text="Invalid device selected. Please select a valid device."
  fi
  selected_device=$(zenity --list --title="Select Device" --text="Please select your device:" --column "Devices" "${options[@]}" 2>/dev/null)
  selected_device="/dev/$selected_device"
done
 
 
 # Check if disk has at least 50GB
 DISK_SIZE=$(blockdev --getsize64 "$selected_device")
 REQUIRED_SIZE=$((50*1024*1024*1024)) # 50GB in bytes
if [ "$DISK_SIZE" -lt "$REQUIRED_SIZE" ]; then
     autoPart="no"
     zenity --error --text="Error: Selected device size is less than 50GB, Use manual partitionning or select another Device"
     auto_part
else

    # Make Variable for partitioning depending on detecting device and choosen options
  if [[ "$selected_device" =~ ^/dev/nvme[0-9]n[0-9]$ ]]; then

          if [ "$autoHome" = "yes" ] && [ "$autoSwap" = "yes" ]; then
              # NVME disk
              if [ -d /sys/firmware/efi ]; then
                  efi_partition="${selected_device}p1"
                  swap_partition="${selected_device}p2"
                  root_partition="${selected_device}p3"
                  home_partition="${selected_device}p4"
              else
                  swap_partition="${selected_device}p1"
                  root_partition="${selected_device}p2"
                  home_partition="${selected_device}p3"
              fi
          fi   

          if [ "$autoHome" = "no" ] && [ "$autoSwap" = "yes" ]; then
              # NVME disk
              if [ -d /sys/firmware/efi ]; then
                  efi_partition="${selected_device}p1"
                  swap_partition="${selected_device}p2"
                  root_partition="${selected_device}p3"
              else
                  swap_partition="${selected_device}p1"
                  root_partition="${selected_device}p2"
              fi
          fi   

          if [ "$autoHome" = "yes" ] && [ "$autoSwap" = "no" ]; then
              # NVME disk
              if [ -d /sys/firmware/efi ]; then
                  efi_partition="${selected_device}p1"
                  root_partition="${selected_device}p2"
                  home_partition="${selected_device}p3"
              else
                  root_partition="${selected_device}p1"
                  home_partition="${selected_device}p2"
              fi
          fi   

          if [ "$autoHome" = "no" ] && [ "$autoSwap" = "no" ]; then
              # NVME disk
              if [ -d /sys/firmware/efi ]; then
                  efi_partition="${selected_device}p1"
                  root_partition="${selected_device}p2"
              else
                  root_partition="${selected_device}p1"
              fi
          fi   

     else

          if [ "$autoHome" = "yes" ] && [ "$autoSwap" = "yes" ]; then
              # sata or virtual disk
              if [ -d /sys/firmware/efi ]; then
                  efi_partition="${selected_device}1"
                  swap_partition="${selected_device}2"
                  root_partition="${selected_device}3"
                  home_partition="${selected_device}4"
              else
                  swap_partition="${selected_device}1"
                  root_partition="${selected_device}2"
                  home_partition="${selected_device}3"
              fi
          fi   

          if [ "$autoHome" = "no" ] && [ "$autoSwap" = "yes" ]; then
              # sata or virtual disk
              if [ -d /sys/firmware/efi ]; then
                  efi_partition="${selected_device}1"
                  swap_partition="${selected_device}2"
                  root_partition="${selected_device}3"
              else
                  swap_partition="${selected_device}1"
                  root_partition="${selected_device}2"
              fi
          fi   

          if [ "$autoHome" = "yes" ] && [ "$autoSwap" = "no" ]; then
              # sata or virtual disk
              if [ -d /sys/firmware/efi ]; then
                  efi_partition="${selected_device}1"
                  root_partition="${selected_device}2"
                  home_partition="${selected_device}3"
              else
                  root_partition="${selected_device}1"
                  home_partition="${selected_device}2"
              fi
          fi   

          if [ "$autoHome" = "no" ] && [ "$autoSwap" = "no" ]; then
              # sata or virtual disk
              if [ -d /sys/firmware/efi ]; then
                  efi_partition="${selected_device}1"
                  root_partition="${selected_device}2"
              else
                  root_partition="${selected_device}1"
              fi
          fi
  fi

   #confirm with the user that data will be Erased
   if zenity --question --text="Are you sure you want to Format the selected device : $selected_device , all data on that device is going to be Erased !" --ok-label="Yes" --cancel-label="No"; then
      if [ "$autoHome" = "yes" ] && [ "$autoSwap" = "yes" ]; then
              if [ -d /sys/firmware/efi ]; then
                  # Create partition table
                  parted -s $selected_device mklabel gpt

                  # Create EFI partition
                  parted -a opt $selected_device mkpart EFI fat32 1MiB 513MiB
                  parted $selected_device set 1 boot on
                  set_option EFIPART $efi_partition

                  # Create swap partition
                  parted -a opt $selected_device mkpart swap linux-swap 513MiB 4.5GiB

                  # Create root partition
                  parted -a opt $selected_device mkpart root ext4 4.5GiB 44.5GiB

                  # Create home partition using the rest of the disk space
                  parted -a opt $selected_device mkpart home ext4 44.5GiB 100%

                  #Formating Efi partition
                  mkfs.vfat -F32 ${efi_partition}
                  uuid2=$(blkid -o value -s UUID $efi_partition)
                  set_option EFIUUID $uuid2

                  #Formating Swap partition
                  set_option SWAPPART "$swap_partition"
                  mkswap "$swap_partition"
                  uuid4=$(blkid -o value -s UUID "$swap_partition")
                  set_option SWAPUUID "$uuid4"

                  #Formating Root Partition
                  set_option ROOTPART "$root_partition"
                  mkfs.btrfs -L ROOT -m single -f $root_partition
                  uuid3=$(blkid -o value -s UUID $root_partition)
                  set_option ROOTUUID $uuid3
                  rootdevice=$(lsblk --noheadings --output pkname "$root_partition")
                  rootdevice="/dev/$rootdevice"
                  set_option ROOTDEV "$rootdevice"

                  #Formating Home partition
                  if [ "$autoHomeFs" = "btrfs" ]; then
                  mkfs.btrfs -L HOME -m single -f "$home_partition"
                   else
                  mkfs.ext4 -L HOME "$home_partition"
                  fi           
                  uuid5=$(blkid -o value -s UUID $home_partition)
                  set_option HOMEUUID $uuid5


              else


                  # Create partition table
                  parted -s $selected_device mklabel msdos

                  # Create swap partition
                  parted -a opt $selected_device mkpart primary linux-swap 1MiB 4.5GiB

                  # Create root partition
                  parted -a opt $selected_device mkpart primary ext4 4.5GiB 44.5GiB

                  # Create home partition using the rest of the disk space
                  parted -a opt $selected_device mkpart primary ext4 44.5GiB 100%


                  #Formating Swap partition
                  set_option SWAPON "yes"
                  set_option SWAPPART "$swap_partition"
                  mkswap "$swap_partition"
                  uuid4=$(blkid -o value -s UUID "$swap_partition")
                  set_option SWAPUUID "$uuid4"

                  #Formating Root Partition
                  set_option ROOTPART "$root_partition"
                  mkfs.btrfs -L ROOT -m single -f $root_partition
                  uuid3=$(blkid -o value -s UUID $root_partition)
                  set_option ROOTUUID $uuid3
                  rootdevice=$(lsblk --noheadings --output pkname "$root_partition")
                  rootdevice="/dev/$rootdevice"
                  set_option ROOTDEV "$rootdevice"

                  #Formating Home partition
                  if [ "$autoHomeFs" = "btrfs" ]; then
                  mkfs.btrfs -L HOME -m single -f "$home_partition"
                   else
                  mkfs.ext4 -L HOME "$home_partition"
                  fi           
                  uuid5=$(blkid -o value -s UUID $home_partition)
                  set_option HOMEUUID $uuid5

              fi
          fi   

          if [ "$autoHome" = "no" ] && [ "$autoSwap" = "yes" ]; then
              if [ -d /sys/firmware/efi ]; then
                  # Create partition table
                  parted -s $selected_device mklabel gpt

                  # Create EFI partition
                  parted -a opt $selected_device mkpart EFI fat32 1MiB 513MiB
                  parted $selected_device set 1 boot on
                  set_option EFIPART $efi_partition

                  # Create swap partition
                  parted -a opt $selected_device mkpart swap linux-swap 513MiB 4.5GiB

                  # Create root partition
                  parted -a opt $selected_device mkpart root ext4 4.5GiB 100%

                  #Formating Efi partition
                  mkfs.vfat -F32 ${efi_partition}
                  uuid2=$(blkid -o value -s UUID $efi_partition)
                  set_option EFIUUID $uuid2

                  #Formating Swap partition
                  set_option SWAPPART "$swap_partition"
                  mkswap "$swap_partition"
                  uuid4=$(blkid -o value -s UUID "$swap_partition")
                  set_option SWAPUUID "$uuid4"

                  #Formating Root Partition
                  set_option ROOTPART "$root_partition"
                  mkfs.btrfs -L ROOT -m single -f $root_partition
                  uuid3=$(blkid -o value -s UUID $root_partition)
                  set_option ROOTUUID $uuid3
                  rootdevice=$(lsblk --noheadings --output pkname "$root_partition")
                  rootdevice="/dev/$rootdevice"
                  set_option ROOTDEV "$rootdevice"


              else

                  # Create partition table
                  parted -s $selected_device mklabel msdos

                  # Create swap partition
                  parted -a opt $selected_device mkpart primary linux-swap 1MiB 4.5GiB

                  # Create root partition
                  parted -a opt $selected_device mkpart primary ext4 4.5GiB 100%

                  #Formating Swap partition
                  set_option SWAPPART "$swap_partition"
                  mkswap "$swap_partition"
                  uuid4=$(blkid -o value -s UUID "$swap_partition")
                  set_option SWAPUUID "$uuid4"

                  #Formating Root Partition
                  set_option ROOTPART "$root_partition"
                  mkfs.btrfs -L ROOT -m single -f $root_partition
                  uuid3=$(blkid -o value -s UUID $root_partition)
                  set_option ROOTUUID $uuid3
                  rootdevice=$(lsblk --noheadings --output pkname "$root_partition")
                  rootdevice="/dev/$rootdevice"
                  set_option ROOTDEV "$rootdevice"

              fi
          fi   

          if [ "$autoHome" = "yes" ] && [ "$autoSwap" = "no" ]; then
              if [ -d /sys/firmware/efi ]; then
                  # Create partition table
                  parted -s $selected_device mklabel gpt

                  # Create EFI partition
                  parted -a opt $selected_device mkpart EFI fat32 1MiB 513MiB
                  parted $selected_device set 1 boot on
                  set_option EFIPART $efi_partition

                  # Create root partition
                  parted -a opt $selected_device mkpart root ext4 513MiB 40.5GiB

                  # Create home partition using the rest of the disk space
                  parted -a opt $selected_device mkpart home ext4 40.5GiB 100%

                  #Formating Efi partition
                  mkfs.vfat -F32 ${efi_partition}
                  uuid2=$(blkid -o value -s UUID $efi_partition)
                  set_option EFIUUID $uuid2

                  #Formating Root Partition
                  set_option ROOTPART "$root_partition"
                  mkfs.btrfs -L ROOT -m single -f $root_partition
                  uuid3=$(blkid -o value -s UUID $root_partition)
                  set_option ROOTUUID $uuid3
                  rootdevice=$(lsblk --noheadings --output pkname "$root_partition")
                  rootdevice="/dev/$rootdevice"
                  set_option ROOTDEV "$rootdevice"

                  #Formating Home partition
                  if [ "$autoHomeFs" = "btrfs" ]; then
                  mkfs.btrfs -L HOME -m single -f "$home_partition"
                   else
                  mkfs.ext4 -L HOME "$home_partition"
                  fi           
                  uuid5=$(blkid -o value -s UUID $home_partition)
                  set_option HOMEUUID $uuid5

              else

                  # Create partition table
                  parted -s $selected_device mklabel msdos

                  # Create root partition
                  parted -a opt $selected_device mkpart primary ext4 1MiB 40GiB

                  # Create home partition using the rest of the disk space
                  parted -a opt $selected_device mkpart primary ext4 40GiB 100%

                  #Formating Root Partition
                  set_option ROOTPART "$root_partition"
                  mkfs.btrfs -L ROOT -m single -f $root_partition
                  uuid3=$(blkid -o value -s UUID $root_partition)
                  set_option ROOTUUID $uuid3
                  rootdevice=$(lsblk --noheadings --output pkname "$root_partition")
                  rootdevice="/dev/$rootdevice"
                  set_option ROOTDEV "$rootdevice"

                  #Formating Home partition
                  if [ "$autoHomeFs" = "btrfs" ]; then
                  mkfs.btrfs -L HOME -m single -f "$home_partition"
                   else
                  mkfs.ext4 -L HOME "$home_partition"
                  fi           
                  uuid5=$(blkid -o value -s UUID $home_partition)
                  set_option HOMEUUID $uuid5


              fi
          fi   

          if [ "$autoHome" = "no" ] && [ "$autoSwap" = "no" ]; then
              if [ -d /sys/firmware/efi ]; then
                  # Create partition table
                  parted -s $selected_device mklabel gpt

                  # Create EFI partition
                  parted -a opt $selected_device mkpart EFI fat32 1MiB 513MiB
                  parted $selected_device set 1 boot on
                  set_option EFIPART $efi_partition
                  # Create root partition
                  parted -a opt $selected_device mkpart root ext4 513MiB 100%

                  #Formating Efi partition
                  mkfs.vfat -F32 ${efi_partition}
                  uuid2=$(blkid -o value -s UUID $efi_partition)
                  set_option EFIUUID $uuid2

                  #Formating Root Partition
                  set_option ROOTPART "$root_partition"
                  mkfs.btrfs -L ROOT -m single -f $root_partition
                  uuid3=$(blkid -o value -s UUID $root_partition)
                  set_option ROOTUUID $uuid3
                  rootdevice=$(lsblk --noheadings --output pkname "$root_partition")
                  rootdevice="/dev/$rootdevice"
                  set_option ROOTDEV "$rootdevice"

              else

                  # Create partition table
                  parted -s $selected_device mklabel msdos

                  # Create root partition
                  parted -a opt $selected_device mkpart primary ext4 1MiB 100%

                  #Formating Root Partition
                  set_option ROOTPART "$root_partition"
                  mkfs.btrfs -L ROOT -m single -f $root_partition
                  uuid3=$(blkid -o value -s UUID $root_partition)
                  set_option ROOTUUID $uuid3
                  rootdevice=$(lsblk --noheadings --output pkname "$root_partition")
                  rootdevice="/dev/$rootdevice"
                  set_option ROOTDEV "$rootdevice"

              fi
          fi
   fi
fi  

partprobe ${selected_device}

}



function partition_check {
    # Prompt the user with a clickable option to check if they are ready
    zenity --question --text="Are your partitions ready?" --ok-label="Yes" --cancel-label="No"
    if [ $? -eq 1 ]; then
         zenity --info --text="Close Gparted When Done"
        # Launch GParted and wait for it to close
        gparted &
        while pgrep gparted >/dev/null; do sleep 1; done
    fi
    partitions=$(lsblk -rno NAME,TYPE,SIZE | awk '$2 == "part" && $1 !~ /^(sr0|loop)/ {split($1,a,""); if (a[length(a)] ~ /[0-9]/) print $1}')
}



function timezone() {
  # Added this from arch wiki https://wiki.archlinux.org/title/System_time
  timezone="$(curl --fail https://ipapi.co/timezone)"

  # Zenity prompt to confirm detected timezone
  if zenity --question --text="System detected your timezone to be '$timezone'. Is this correct?" --title="Timezone Detection"; then
    zenity --info --text="${timezone} set as timezone." --title="Timezone Set"
    set_option TIMEZONE $timezone
  else
    while true; do
      new_timezone=$(zenity --entry --text="Please enter your desired timezone e.g. Europe/London:" --title="Timezone Selection")

      # Verify that the timezone entered is valid
      if tzselect <<< "$new_timezone" >/dev/null 2>&1; then
        zenity --info --text="${new_timezone} set as timezone." --title="Timezone Set"
        set_option TIMEZONE $new_timezone
        break
      else
        zenity --error --text="Invalid timezone entered. Please try again." --title="Timezone Selection Error"
        firefox 'https://wiki.archlinux.org/title/System_time#Time_zone' &
      fi
    done
  fi
}



function localeselect() {
  # Get a list of available locales
  options=($(locale -a) en_CA.UTF-8 en_HK.UTF-8 en_US.UTF-8 fr_CA.UTF-8 fr_FR.UTF-8 zh_CN.UTF-8 zh_TW.UTF-8 hu.UTF-8 it_IT.UTF-8 ja_JP.UTF-8 ru_RU.UTF-8 es_ES.UTF-8 de_DE.UTF-8 ar_SA.UTF-8 af_ZA.UTF-8)
  # Zenity prompt to select locale
  locale=$(zenity --list --text="Please select your locale from this list:" --title="Locale Selection" --column="Locale" "${options[@]}")
  # Zenity prompt to confirm selected locale
  if zenity --question --text="Your locale: ${locale}. Is this correct?" --title="Locale Confirmation"; then
    set_option LANGLOCAL $locale
  else
  localeselect
  fi
}



function keymap() {
  # These are default key maps as presented in official arch repo archinstall
  options=(by ca cf cz de dk es et fa fi fr gr hu il it lt lv mk nl no pl ro ru sg ua uk us)
    # Zenity prompt to select keymap
    keymap=$(zenity --list --text="Please select your keyboard layout from this list:" --title="Keymap Selection" --column="Keymap" "${options[@]}")
    # Zenity prompt to confirm selected keymap
    if zenity --question --text="Your keyboard layout: ${keymap}. Is this correct?" --title="Keymap Confirmation"; then
       set_option KEYMAP $keymap
       loadkeys $keymap
     #  xfconf-query -c keyboard-layout -p /Default/XkbLayout -s $keymap
    else
       keymap
    fi
}



function loginshell() {
    # Define available options
    options=("bash" "fish" "zsh")
    shellchoice=$(zenity --list --title="Login Shell" --text="Please select a login shell" --column="Shells" "${options[@]}")
    if zenity --question --text="You have selected '$shellchoice'. Is this correct?" --title="Confirmation"; then
        set_option SHELLCHOICE $shellchoice
    else
        loginshell
    fi
}



function desktopenv () {
    options=(kaidaplasma fullplasma minimalplasma gnome fullgnome xfce fullxfce fullMATE MATE cinnamon fulldeepin deepin lxqt i3gaps xmonad openbox bspwm none)
    dechoice=$(zenity --list --title="Select Desktop Environment" --text="Please select an environment from this list" --column="Options" "${options[@]}")
    if zenity --question --title="Confirmation" --text="Your environment: ${dechoice}. Is this correct?" --ok-label="Yes" --cancel-label="No"; then
        set_option DECHOICE $dechoice
    else
        desktopenv
    fi
}



function kernelselect () {
  # Prompt user to select a kernel
  options=(linux linux-zen linux-hardened linux-lts)
  kernelchoice=$(zenity --list --text "Please select a kernel from this list" --title "Kernel Selection" --column "Kernel" "${options[@]}")
  # Prompt user to confirm selected kernel
  if zenity --question --text "Your kernel: ${kernelchoice}. Is this correct?" --title "Kernel Confirmation"; then
    set_option KERNELCHOICE $kernelchoice
  else
    kernelselect
  fi
}



function custompkg () {
    if zenity --question --text="Do you want Some Additionnal packages ?" --title="Extra packages"; then
        # Prompt the user to enter a list of packages using Zenity
        package_list=$(zenity --entry --title="Package List" --text="Please enter a list of packages separated by spaces:")
        # Split the user input into an array of package names
        IFS=' ' read -r -a packages <<< "$package_list"
        # Verify that all packages exist
        packages_exist="yes"
        for package in "${packages[@]}"
        do
            if ! pacman -Ss "$package" > /dev/null 2>&1; then
                zenity --error --title="Error" --text="Package '$package' not found"
                packages_exist="no"
                custompkg       
            fi
        done

        # If all packages exist, save the list to a variable for later use
        if [ "$packages_exist" == "yes" ]; then
            package_var=$(echo "${packages[@]}")
            zenity --info --title="Packages Found" --text="Those extra will be installed : $package_var"
            set_option EXTRAPKG "$package_var"
            set_option PKGWANT yes
            packages_exist="done"
        fi
    fi
}



function lib32repo() {
  libchoice=$(zenity --list --text "Do you want the Multilib repo?" --column "Options" "yes" "no")

  if zenity --question --text="Your choice: $libchoice\nIs this correct?" --ok-label="Yes" --cancel-label="No"; then
    set_option LIBCHOICE $libchoice
  else
    lib32repo
  fi
}



function AurHelper () {
    aurchoice=$(zenity --list --title="AUR Helper" --text="Please select an aur helper from this list" --column="Options" "none" "yay" "paru" "octopi-paru" "octopi-yay")
    
    if zenity --question --title="Confirm" --text="Your choice : ${aurchoice}\nIs this correct?"; then
        set_option AURCHOICE $aurchoice
    else
        AurHelper
    fi
}



function chaorepo() {
  chaochoice=$(zenity --list --title="Chaotic-Aur Repo" --text="Do you want the Chaotic-Aur repo?" --column="Options" "no" "yes")

  if zenity --question --title="Confirm" --text="Your choice: ${chaochoice}. Is this correct?"; then
    set_option CHAOCHOICE $chaochoice
  else
    chaorepo
  fi
}



function blackarch () {
    blackchoice=$(zenity --list --title="BlackArch Repo" --text="Do you want the BlackArch repo ?" --column="Options" "no" "yes")
     if zenity --question --title="Confirm" --text="Your choice : ${blackchoice}\nIs this correct?"; then
        set_option BLACKCHOICE $blackchoice
    else
        blackarch
     fi
}



function userinfo () {
while true; do
  username=$(zenity --entry --text="Choose A Username:" 2>/dev/null)
  if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    zenity --error --text "Invalid username. Usernames must start with a letter or underscore, and only contain letters, digits, hyphens, and underscores."
  else
        if zenity --question --text="Your Username: ${username}. Is this correct?" --title="Username Confirmation"; then
          set_option USERNAME "${username}"
          break
        else
          userinfo
        fi
  fi
done
}



function userpass () {
while true; do
password=$(zenity --password --text "Please enter the User password:" --title "Enter User Password" 2>/dev/null)
password2=$(zenity --password --text "Please confirm the User password:" --title "Confirm User Password" 2>/dev/null)
  if [ "$password" = "$password2" ]; then
    set_option PASSWORD "${password}"
    break
  else
    zenity --error --text "Passwords do not match. Please try again."
  fi
done
}



function rootpass () {
while true; do
zenity --info --text="Please Enter the password for Root now" --title="Root Password"
rootpassword=$(zenity --password --text "Please enter the root password:" --title "Enter Root Password" 2>/dev/null)
rootpassword2=$(zenity --password --text "Please confirm the root password:" --title "confirm Root Password" 2>/dev/null)
  if [ "$rootpassword" = "$rootpassword2" ]; then
    set_option ROOTPASSWORD "${rootpassword}"
    break
  else
    zenity --error --text "Passwords do not match. Please try again."
  fi
done
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
  if zenity --question --text="Your hostname is ${hostname}. Is this correct?" --title="Confirmation" 2>/dev/null ; then
    set_option NAME_OF_MACHINE "$hostname"
  else
    myhostname
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



function swappartition() {
    # Ask user if they have a Swap partition
    if zenity --question --text="Do you have a Swap partition?"; then
        set_option SWAPON "yes"
        swappartition2
    else
        zenity --info --text="No Swap partition will be used." 2>/dev/null
    fi
}




function swappartition2() {
        # Ask user to select Swap partition
        # Create a list of options using available partitions
        partitions=$(lsblk -rno NAME,TYPE,SIZE | awk '$2 == "part" && $1 !~ /^(sr0|loop)/ {split($1,a,""); if (a[length(a)] ~ /[0-9]/) print $1}')
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
    partitions=$(lsblk -rno NAME,TYPE,SIZE | awk '$2 == "part" && $1 !~ /^(sr0|loop)/ {split($1,a,""); if (a[length(a)] ~ /[0-9]/) print $1}')
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



function efipartition() {
    # Create a list of options using available partitions
    partitions=$(lsblk -rno NAME,TYPE,SIZE | awk '$2 == "part" && $1 !~ /^(sr0|loop)/ {split($1,a,""); if (a[length(a)] ~ /[0-9]/) print $1}')
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
    partitions=$(lsblk -rno NAME,TYPE,SIZE | awk '$2 == "part" && $1 !~ /^(sr0|loop)/ {split($1,a,""); if (a[length(a)] ~ /[0-9]/) print $1}')
    options=()
    for partition in $partitions; do
        options+=("$partition")
    done
    # Ask user to choose a partition
    lsblk
    partition3=$(zenity --list --title "Choose Root Partition" --text "Choose a Root partition to use:" --column "Partitions" "${options[@]}" 2>/dev/null)
    if [[ -z "$partition3" ]]; then
        zenity --error --text "No partition selected."
        roorpartition
    fi
    set_option ROOTPART "$partition3"
    mkfs.btrfs -L ROOT -m single -f $partition3
    uuid3=$(blkid -o value -s UUID $partition3)
    set_option ROOTUUID $uuid3
    rootdevice=$(lsblk --noheadings --output pkname "$partition3")
    rootdevice="/dev/$rootdevice"
    set_option ROOTDEV "$rootdevice"
}

function pacstartup() {

    #make sure pacman is fine before checking for packages
    pacman-key --init
    pacman-key --populate archlinux
    pacman -Sy archlinux-keyring --needed --noconfirm
    sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
    pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
    pacman-key --lsign-key FBA220DFC880C036
    pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
    cat /root/archscript/mirror.txt >> /etc/pacman.conf
    pacman -Sy  chaotic-keyring --needed --noconfirm
    reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

}

function manualpart() {

     if [ "$autoPart" = "no" ]; then
      partition_check
      if [ "$firmtype" = "UEFI" ]; then
        efipartition
        efiformat
        uuid2=$(blkid -o value -s UUID $partition2)
        set_option EFIUUID $uuid2
      fi
      swappartition
      homepartition
      rootpartition 
    fi

}

    #Executing this script functions
    
    
    pacstartup&
    auto_part
    #Manual partition part if not using auto_part
    manualpart
    #User Configs
    keymap 
    userinfo
    userpass
    rootpass
    myhostname
    timezone
    localeselect
    lsblk
    loginshell
    desktopenv
    kernelselect
    custompkg
    lib32repo
    AurHelper
    chaorepo
    blackarch
    zenity --info --text="The System Will Now install according to the selected options" --title="Installing" --timeout=15&
