#!/usr/bin/env bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/config.sh

clear
logo



echo -ne "

-------------------------------------------------------------------------
                    Setup Language to EN and set Admin rights
-------------------------------------------------------------------------
"
sed -i "s/^#${LANGLOCAL}/${LANGLOCAL}/" /etc/locale.gen
locale-gen


systemctl enable --now NetworkManager

# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers


#Add parallel downloading
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

if [ "$LIBCHOICE" = "yes" ]; then 
#Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm
fi

clear
logo
echo -ne "
-------------------------------------------------------------------------
                    Adding User
-------------------------------------------------------------------------
"

groupadd libvirt

if [ "$SHELLCHOICE" = "bash" ]; then
      useradd -m -G wheel,libvirt -s /bin/bash $USERNAME
   elif [ "$SHELLCHOICE" = "fish" ]; then
      useradd -m -G wheel,libvirt -s /bin/fish $USERNAME
         elif [ "$SHELLCHOICE" = "osh" ]; then
      useradd -m -G wheel,libvirt -s /bin/osh $USERNAME
         elif [ "$SHELLCHOICE" = "zsh" ]; then
      useradd -m -G wheel,libvirt -s /bin/zsh $USERNAME
fi



# use chpasswd to enter $USERNAME:$password
echo "$USERNAME:$PASSWORD" | chpasswd
echo "root:$ROOTPASSWORD" | chpasswd

mkinitcpio -P

umount /.snapshots
rm -r /.snapshots
snapper --no-dbus -c root create-config /
btrfs subvolume delete /.snapshots
mkdir /.snapshots
mount -a
chmod 750 /.snapshots

clear
logo
echo -ne "
-------------------------------------------------------------------------
                  Display manager service activation
-------------------------------------------------------------------------
"

if [ "$DECHOICE" = "kaidaplasma" ]; then

      git clone https://github.com/k-arch27/dotfiles
      cp -a ./dotfiles/. /home/$USERNAME/.config/
      rm -Rfd ./dotfiles


   elif [ "$DECHOICE" = "fullplasma" ]; then

      systemctl enable sddm

   elif [ "$DECHOICE" = "minimalplasma" ]; then

      systemctl enable sddm

   elif [ "$DECHOICE" = "gnome" ]; then

      systemctl enable gdm

   elif [ "$DECHOICE" = "fullgnome" ]; then

      systemctl enable gdm
      
   elif [ "$DECHOICE" = "xfce" ]; then

      systemctl enable sddm

   elif [ "$DECHOICE" = "fullxfce" ]; then

      systemctl enable sddm

   elif [ "$DECHOICE" = "MATE" ]; then

      systemctl enable sddm
      
   elif [ "$DECHOICE" = "fullMATE" ]; then

      systemctl enable sddm
      
   elif [ "$DECHOICE" = "cinnamon" ]; then

      systemctl enable sddm

   elif [ "$DECHOICE" = "deepin" ]; then

      systemctl enable sddm

   elif [ "$DECHOICE" = "fulldeepin" ]; then

      systemctl enable sddm

   elif [ "$DECHOICE" = "lxqt" ]; then

      systemctl enable sddm

   elif [ "$DECHOICE" = "i3gaps" ]; then

      systemctl enable sddm

   elif [ "$DECHOICE" = "xmonad" ]; then

      systemctl enable sddm

   elif [ "$DECHOICE" = "openbox" ]; then

      systemctl enable sddm
   else

      echo -ne "no Gui was choosen"

fi

clear
logo
echo -ne "
-------------------------------------------------------------------------
                  Grub Install
-------------------------------------------------------------------------
"

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Arch-Btrfs --modules="normal test efi_gop efi_uga search echo linux all_video gfxmenu gfxterm_background gfxterm_menu gfxterm loadenv configfile gzio part_gpt btrfs"

sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub


sed -i 's/rootflags=subvol=${rootsubvol}//' /etc/grub.d/10_linux
sed -i 's/rootflags=subvol=${rootsubvol}//' /etc/grub.d/20_linux_xen
sed -i 's|,subvolid=258,subvol=/@/.snapshots/1/snapshot| |' /etc/fstab


grub-mkconfig -o /boot/grub/grub.cfg
