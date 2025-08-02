#!/bin/bash
pacman -S git
git clone https://github.com/supermariofps/hatsune-miku-windows-linux-cursors.git

if [ -d "$HOME/Downloads/hatsune-miku-windows-linux-cursors/miku-cursor-linux" ]; then
    sudo mv "$HOME/Downloads/hatsune-miku-windows-linux-cursors/miku-cursor-linux" /usr/share/icons/
    echo "Folder miku-cursor-linux has been moved to /usr/share/icons/"
else
    echo "Error: miku-cursor-linux folder not found in Downloads"
    exit 1
fi