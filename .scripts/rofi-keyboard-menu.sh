#!/usr/bin/env bash

de="German  ( de )"
en="English ( us )"
es="Spanish ( es )"

chosen_keyboard=$(echo -e "$de\n$en\n$es" | uniq -u | rofi -dmenu -i -selected-row 0 -p "Keyboard Layout: " )

read -r chosen_id <<< "${chosen_keyboard:3}"

if [ "$chosen_keyboard" = "" ]; then
	exit
elif [ "$chosen_keyboard" = "German  ( de )" ]; then
	setxkbmap de
elif [ "$chosen_keyboard" = "English ( us )" ]; then
	setxkbmap us
elif [ "$chosen_keyboard" = "Spanish ( es )" ]; then
  setxkbmap es
else
  setxkbmap de
fi
