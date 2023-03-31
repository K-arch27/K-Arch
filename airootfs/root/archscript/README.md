# archscript (UEFI Version)
## My own arch install script with Btrfs and snapper Setup

### -----------Options Included-----------


- Choice of Desktop environements/Tiling Manager


- Choice of User Login Shell (bash, fish, zsh)


- Choice for Multilib Repo


- Choice for BlackArch Repo


- Choice for Chaoctic-aur repo

- Choice of Aur helper/Pacman Frontend (yay, paru, octopi + yay, octopi + paru)


- Choice for Including /home or not inside of the main subvolume for snapshot


- Choice For formating /home to Ext4 or Btrfs Or to Keep it As is If on a different partition

### -----------Important Information-----------

- Pre-requisite:

Partition needs to be done before launching the script 
(Or Done on TTY2 while the script First Ask for the Partition if you forgot)



- KNOW BUG:

-When Inputing text into the script (Username, Password, Hostname, etc..) special characters will break the script
(Please Avoid Any special Character)
(For now I recommand entering a simple password and changing it after the installation if you want special charaters like @"' inside of it) 




- Post-Install : 

Deleting the directory /root/archscript if not needed
(Not automated so logs can be check if needed)


### ------------Install Instruction------------

1: Boot on Arch Iso And partition your drive(s)


2: Ensure keyring is updated and Get git on the iso : pacman -Sy archlinux-keyring --needed && pacman -S git


3: Download the script : git clone https://github.com/K-arch27/archscript.git


4: Enter the directory of the script : cd archscript


5: Give the script permission to be executed : chmod +x ./start.sh


6: Launch it : ./start.sh


7: Make the choice that suit yourself when prompted


8: Sit back and enjoy
