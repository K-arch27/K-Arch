#!/usr/bin/env bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/config.sh


echo -ne "

-------------------------------------------------------------------------
                    Setup Locale, Keymaps and sudo rights
-------------------------------------------------------------------------
"

sed -i "s/^#${LANGLOCAL}/${LANGLOCAL}/" /etc/locale.gen
locale-gen
echo KEYMAP=$KEYMAP > /etc/vconsole.conf
echo "LANG=${LANGLOCAL}" > /etc/locale.conf

if systemctl status NetworkManager >/dev/null 2>&1; then
systemctl enable --now NetworkManager
fi

# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers


#Add parallel downloading
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf


mkinitcpio -P


echo -ne "
-------------------------------------------------------------------------
                    Setup hostname and timezone
-------------------------------------------------------------------------
"
echo "$NAME_OF_MACHINE" > /etc/hostname
ln -s /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc 



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


echo -ne "
-------------------------------------------------------------------------
                  Display manager service activation
-------------------------------------------------------------------------
"

if [ "$DECHOICE" = "kaidaplasma" ]; then

      git clone https://github.com/k-arch27/dotfiles
      cp -a ./dotfiles/. /home/$USERNAME/.config/
      chown -R $USERNAME /home/$USERNAME/.config/
      rm -Rfd ./dotfiles

   elif [ "$DECHOICE" = "gnome" ]; then

      systemctl enable gdm

   elif [ "$DECHOICE" = "fullgnome" ]; then

      systemctl enable gdm
      
   elif [ "$DECHOICE" = "none" ]; then
   
      echo -ne "no Gui was choosen"

   else
   
      systemctl enable sddm


fi


echo -ne "
-------------------------------------------------------------------------
                  Extra Repo
-------------------------------------------------------------------------
"


if [ "$LIBCHOICE" = "yes" ]; then 
  sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
  pacman -Sy --noconfirm
fi

if [ "$CHAOCHOICE" = "yes" ]; then
  pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
  pacman-key --lsign-key FBA220DFC880C036
  pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
  cat /root/archscript/mirror.txt >> /etc/pacman.conf
fi

if [ "$BLACKCHOICE" = "yes" ]; then
  curl -O https://blackarch.org/strap.sh
  chmod +x strap.sh
  bash strap.sh
  rm /strap.sh
fi

echo -ne "
-------------------------------------------------------------------------
                  Snapper Subvolume setup
-------------------------------------------------------------------------
"

umount /.snapshots
rm -r /.snapshots
snapper --no-dbus -c root create-config /
btrfs subvolume delete /.snapshots
mkdir /.snapshots
mount -a
chmod 750 /.snapshots

#Changing The timeline auto-snap
sed -i 's|QGROUP=""|QGROUP="1/0"|' /etc/snapper/configs/root
sed -i 's|NUMBER_LIMIT="50"|NUMBER_LIMIT="5-15"|' /etc/snapper/configs/root
sed -i 's|NUMBER_LIMIT_IMPORTANT="50"|NUMBER_LIMIT_IMPORTANT="5-10"|' /etc/snapper/configs/root
sed -i 's|TIMELINE_LIMIT_HOURLY="10"|TIMELINE_LIMIT_HOURLY="2"|' /etc/snapper/configs/root
sed -i 's|TIMELINE_LIMIT_DAILY="10"|TIMELINE_LIMIT_DAILY="2"|' /etc/snapper/configs/root
sed -i 's|TIMELINE_LIMIT_WEEKLY="0"|TIMELINE_LIMIT_WEEKLY="2"|' /etc/snapper/configs/root
sed -i 's|TIMELINE_LIMIT_MONTHLY="10"|TIMELINE_LIMIT_MONTHLY="0"|' /etc/snapper/configs/root
sed -i 's|TIMELINE_LIMIT_YEARLY="10"|TIMELINE_LIMIT_YEARLY="0"|' /etc/snapper/configs/root


#activating the auto-cleanup
SCRUB=$(systemd-escape --template btrfs-scrub@.timer --path /dev/disk/by-uuid/${ROOTUUID})
systemctl enable ${SCRUB}
systemctl enable snapper-timeline.timer
systemctl enable snapper-cleanup.timer


echo -ne "
-------------------------------------------------------------------------
                  Grub Install
-------------------------------------------------------------------------
"

if [ -d /sys/firmware/efi ]; then
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Arch-Btrfs --modules="normal test efi_gop efi_uga search echo linux all_video gfxmenu gfxterm_background gfxterm_menu gfxterm loadenv configfile gzio part_gpt btrfs"
else
grub-install --target=i386-pc $ROOTDEV --modules="normal test echo linux all_video gfxmenu gfxterm_background gfxterm_menu gfxterm loadenv configfile gzio part_gpt btrfs"
fi

sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub

sed -i 's/rootflags=subvol=${rootsubvol}//' /etc/grub.d/10_linux
sed -i 's/rootflags=subvol=${rootsubvol}//' /etc/grub.d/20_linux_xen
sed -i 's|,subvolid=258,subvol=/@/.snapshots/1/snapshot| |' /etc/fstab


grub-mkconfig -o /boot/grub/grub.cfg

echo -ne "
-------------------------------------------------------------------------
        Updating full system 
-------------------------------------------------------------------------
"

pacman -Syyu --noconfirm
