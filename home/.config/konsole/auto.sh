#!/bin/bash

currenttime=$(date +%H:%M)
if [[ "$currenttime" > "07:00" ]] && [[ "$currenttime" < "18:00" ]]; then
  cp -f "$HOME/.config/konsole/konsolerc_light" "$HOME/.config/konsolerc"
else
  cp -f "$HOME/.config/konsole/konsolerc_dark" "$HOME/.config/konsolerc"
fi