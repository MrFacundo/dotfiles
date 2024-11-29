#!/bin/bash

currenttime=$(date +%H:%M)
if [[ "$currenttime" > "07:00" ]] && [[ "$currenttime" < "18:00" ]]; then
  cp -f "/home/facu/Ricing/konsole/konsolerc_light" "/home/facu/.config/konsolerc"
else
  cp -f "/home/facu/Ricing/konsole/konsolerc_dark" "/home/facu/.config/konsolerc"
fi