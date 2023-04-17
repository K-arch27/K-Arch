#!/bin/bash

# This script will ask users about their prefrences
# like timezone, keyboard layout,
# user name, password, etc.



if [ -d /sys/firmware/efi ]; then
  FIRMWARE_TYPE="UEFI"
else
  FIRMWARE_TYPE="BIOS"
fi



# set up a config file
CONFIG_FILE=/root/archscript/config.sh
source /root/archscript/config.sh



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
            zenity --info --title="Packages Found" --text="Packages found: $package_var"
            set_option EXTRAPKG $package_var
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
        set_option SWAPPART "yes"
        swappartition2
    else
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
}



    partition_check
    partitions=$(lsblk -o NAME,SIZE -p -n -l |  awk '{print $1}')

  
    
    #Executing this script functions
    
    keymap
    userinfo
    userpass
    rootpass
    myhostname
    timezone
    localeselect
    lsblk
    efipartition
    efiformat
    uuid2=$(blkid -o value -s UUID $partition2)
    set_option EFIUUID $uuid2
    swappartition
    homepartition
    rootpartition
    loginshell
    desktopenv
    kernelselect
    
      #make sure pacman is fine before checking for packages
    zenity --info --text="Preparing Pacman Database for packages" --title="Preparing pacman" --timeout=10&
    pacman-key --init
    pacman-key --populate archlinux
    pacman -Sy archlinux-keyring --needed --noconfirm
    sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
    pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
    pacman-key --lsign-key FBA220DFC880C036
    pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
    cat /root/archscript/mirror.txt >> /etc/pacman.conf
    pacman -Sy  chaotic-keyring --needed --noconfirm
    custompkg
    lib32repo
    AurHelper
    chaorepo
    blackarch
    reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
