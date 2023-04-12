#!/bin/bash

    # Prompt the user with a clickable option to check if they are ready
   if [ zenity --question --text="Are you ready to Install?" --ok-label="No" --cancel-label="yes" ]; then
        zenity --info --text="The script can be launched back with Right click on the desktop"
        exit
   fi
   
   
