#!/bin/bash

qdbus org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 3
sleep 1
microsoft-edge '--app=https://app.element.io/#/room/!VOeLKKXGJhjiRQTOJd:matrix.org' --class=WebApp-Element4888 &
sleep 1
teams-for-linux &

sleep 2
qdbus org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 2
sleep 1
code &

sleep 2
qdbus org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 1
sleep 1
firefox --new-window &

sleep 2
qdbus org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 4
sleep 1
thunderbird &

sleep 2
qdbus org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 5
sleep 1
#/var/lib/flatpak/exports/bin/org.chromium.Chromium --app=https://web.whatsapp.com/ --class=WebApp-WhatsApp3987 --name=WebApp-WhatsApp3987 &
ghostty -e "nchat" &
sleep 1
ghostty -e "yt" &

disown -a
exit 0
