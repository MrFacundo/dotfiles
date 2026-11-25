#!/bin/bash

qdbus org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 1
sleep 1
okular /home/facu/Music/Books/Método-H.-Klosé-para-Saxofone.pdf &

sleep 2
qdbus org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 2
sleep 1
firefox --new-window 'https://metronome-online.com/' &

sleep 2
qdbus org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 3
sleep 1
flatpak run --command=bottles-cli com.usebottles.bottles run -b DAW  -e "$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/DAW/drive_c/Program Files/Arturia/Analog Lab V/Analog Lab V.exe" &

disown -a
exit 0
