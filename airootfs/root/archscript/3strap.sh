#!/usr/bin/env bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/config.sh


mkdir /mnt &>/dev/null # Hiding error message if any
clear


echo -ne "

-------------------------------------------------------------------------
   █████╗ ██████╗  ██████╗██╗  ██╗  ██║
  ██╔══██╗██╔══██╗██╔════╝██║  ██║  ██║
  ███████║██████╔╝██║     ███████║  ██║
  ██╔══██║██╔══██╗██║     ██╔══██║  ██║ 
  ██║  ██║██║  ██║╚██████╗██║  ██║  ██║
  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝  ╚═╝
-------------------------------------------------------------------------

"


echo -ne "
-------------------------------------------------------------------------
                    Straping Setup 
-------------------------------------------------------------------------
"




#required Package
if [ "$SHELLCHOICE" = "fish" ]; then
      pacstrap /mnt fish
      
      elif [ "$SHELLCHOICE" = "osh" ]; then
      pacstrap /mnt oil
      
      elif [ "$SHELLCHOICE" = "zsh" ]; then
      pacstrap /mnt zsh
fi
pacstrap /mnt base base-devel linux-firmware e2fsprogs dosfstools grub grub-btrfs os-prober efibootmgr btrfs-progs ntfs-3g snapper snap-pac snap-pac-grub



#Kernel Choice installation

if [ "$KERNELCHOICE" = "linux" ]; then

      pacstrap /mnt linux linux-headers

   elif [ "$KERNELCHOICE" = "linux-zen" ]; then

      pacstrap /mnt linux-zen linux-zen-headers

   elif [ "$KERNELCHOICE" = "linux-hardened" ]; then

      pacstrap /mnt linux-hardened linux-hardened-headers

   elif [ "$KERNELCHOICE" = "linux-lts" ]; then

      pacstrap /mnt linux-lts linux-lts-headers

fi

#Optionnal but usefull packages

pacstrap /mnt networkmanager sof-firmware man-db man-pages texinfo 



#GUI choice installation
if [ "$DECHOICE" = "kaidaplasma" ]; then
      pacstrap /mnt  xorg xorg-server xorg-xinit plasma konsole dolphin dolphin-plugins ark kate kcalc kolourpaint spectacle krunner partitionmanager packagekit-qt5 
      pacstrap /mnt latte-dock discord filelight htop kruler ksysguard yakuake nano starship neofetch firefox git
      pacstrap /mnt noto-fonts-emoji noto-fonts-extra ttf-nerd-fonts-symbols zip unrar arch-install-scripts 

   elif [ "$DECHOICE" = "fullplasma" ]; then

      pacstrap /mnt xorg plasma plasma-wayland-session kde-applications

   elif [ "$DECHOICE" = "minimalplasma" ]; then

      pacstrap /mnt xorg plasma-desktop sddm 

   elif [ "$DECHOICE" = "gnome" ]; then

      pacstrap /mnt gnome

   elif [ "$DECHOICE" = "fullgnome" ]; then

      pacstrap /mnt gnome gnome-extra
      
   elif [ "$DECHOICE" = "xfce" ]; then

      pacstrap /mnt xfce4 sddm 

   elif [ "$DECHOICE" = "fullxfce" ]; then

      pacstrap /mnt xfce4 xfce4-goodies sddm

   elif [ "$DECHOICE" = "MATE" ]; then

      pacstrap /mnt mate sddm

   elif [ "$DECHOICE" = "fullMATE" ]; then

      pacstrap /mnt mate mate-extra sddm
      
   elif [ "$DECHOICE" = "cinnamon" ]; then

      pacstrap /mnt cinnamon sddm

   elif [ "$DECHOICE" = "deepin" ]; then

      pacstrap /mnt deepin sddm

   elif [ "$DECHOICE" = "fulldeepin" ]; then

      pacstrap /mnt deepin deepin-extra sddm
      
   elif [ "$DECHOICE" = "lxqt" ]; then

      pacstrap /mnt xorg lxqt breeze-icons sddm

   elif [ "$DECHOICE" = "i3gaps" ]; then

      pacstrap /mnt xorg xorg-xinit xterm i3-gaps ttf-dejavu dmenu i3status sddm

   elif [ "$DECHOICE" = "xmonad" ]; then

      pacstrap /mnt xmonad xmonad-contrib lightdm sddm
      
  elif [ "$DECHOICE" = "openbox" ]; then

      pacstrap /mnt openbox ttf-dejavu sddm
      
        elif [ "$DECHOICE" = "bspwm" ]; then

      pacstrap /mnt bspwm sxhkd xorg-xinit

   else

      echo -ne "no Gui was choosen so no display manager will be initialized"

fi




if [ "$AURCHOICE" = "yay" ]; then
      pacstrap /mnt yay
      
      elif [ "$AURCHOICE" = "paru" ]; then
      pacstrap /mnt paru
      
      elif [ "$AURCHOICE" = "octopi-paru" ]; then
      pacstrap /mnt paru octopi
      
      elif [ "$AURCHOICE" = "octopi-yay" ]; then
      pacstrap /mnt yay octopi
fi




echo -ne "

-------------------------------------------------------------------------
                    Installing Microcode
-------------------------------------------------------------------------
"
# determine processor type and install microcode
proc_type=$(lscpu)
if grep -E "GenuineIntel" <<< ${proc_type}; then
    echo "Installing Intel microcode"
    pacstrap /mnt intel-ucode
    proc_ucode=intel-ucode.img
elif grep -E "AuthenticAMD" <<< ${proc_type}; then
    echo "Installing AMD microcode"
    pacstrap /mnt amd-ucode
    proc_ucode=amd-ucode.img
fi

clear

genfstab -U /mnt >> /mnt/etc/fstab


cp -R ${SCRIPT_DIR} /mnt/root/archscript
    chmod +x /mnt/root/archscript/4chroot.sh
    chmod +x /mnt/root/archscript/5final.sh
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist


