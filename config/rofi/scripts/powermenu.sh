#!/usr/bin/env bash

## Author : Aditya Shakya (adi1090x) — heavily trimmed
## Rofi   : Power Menu (no confirmation step — immediate action)

# Current Theme
dir="$HOME/.config/rofi/powermenu/type-4"
theme='style-5'

# CMDs
uptime="`uptime -p | sed -e 's/up //g'`"

# Options
shutdown=''  # power-off
reboot=''  # refresh
lock=''  # lock
suspend=''  # moon (sleep)
logout=''  # sign-out

msg=$(printf 'See you soon.\nUptime: %s' "$uptime")

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-p "Goodbye ${USER}" \
		-mesg "$msg" \
		-theme ${dir}/${theme}.rasi \
		-kb-custom-1 's' \
		-kb-custom-2 'l' \
		-kb-custom-3 'r'
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

do_lock() {
	if [[ -x '/usr/bin/hyprlock' ]]; then
		hyprlock
	elif [[ -x '/usr/bin/betterlockscreen' ]]; then
		betterlockscreen -l
	elif [[ -x '/usr/bin/i3lock' ]]; then
		i3lock
	fi
}

do_logout() {
	if [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
		hyprctl dispatch exit
	elif [[ "$DESKTOP_SESSION" == 'openbox' ]]; then
		openbox --exit
	elif [[ "$DESKTOP_SESSION" == 'bspwm' ]]; then
		bspc quit
	elif [[ "$DESKTOP_SESSION" == 'i3' ]]; then
		i3-msg exit
	elif [[ "$DESKTOP_SESSION" == 'plasma' ]]; then
		qdbus org.kde.ksmserver /KSMServer logout 0 0 0
	fi
}

do_suspend() {
	mpc -q pause
	amixer set Master mute
	systemctl suspend
}

# Actions — every path (bare s/l/r, or picking an item and pressing Enter,
# or a mouse click) fires immediately. No confirmation step.
chosen="$(run_rofi)"
rc=$?
case $rc in
	10) systemctl poweroff; exit 0 ;;
	11) do_lock; exit 0 ;;
	12) systemctl reboot; exit 0 ;;
esac

case ${chosen} in
    $shutdown)
		systemctl poweroff
        ;;
    $reboot)
		systemctl reboot
        ;;
    $lock)
		do_lock
        ;;
    $suspend)
		do_suspend
        ;;
    $logout)
		do_logout
        ;;
esac
