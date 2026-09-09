#!/usr/bin/env bash

## Author : Aditya Shakya (adi1090x)
## Github : @adi1090x
#
## Rofi   : Power Menu
#
## Available Styles
#
## style-1   style-2   style-3   style-4   style-5

# Current Theme
dir="$HOME/.config/rofi/powermenu/type-4"
theme='style-5'

# CMDs
uptime="`uptime -p | sed -e 's/up //g'`"
host=`hostname`

# Options
shutdown=''  # power-off
reboot=''  # refresh
lock=''  # lock
suspend=''  # moon (sleep)
logout=''  # sign-out
yes=''  # check
no=''  # times

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-p "Goodbye ${USER}" \
		-mesg "Uptime: $uptime" \
		-theme ${dir}/${theme}.rasi \
		-kb-custom-1 's' \
		-kb-custom-2 'l' \
		-kb-custom-3 'r'
}

# Confirmation CMD
confirm_cmd() {
	rofi -dmenu \
		-p 'Confirmation' \
		-mesg 'Are you Sure?' \
		-theme ${dir}/shared/confirm.rasi
}

# Ask for confirmation
confirm_exit() {
	echo -e "$yes\n$no" | confirm_cmd
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

# Execute Command
run_cmd() {
	selected="$(confirm_exit)"
	if [[ "$selected" == "$yes" ]]; then
		if [[ $1 == '--shutdown' ]]; then
			systemctl poweroff
		elif [[ $1 == '--reboot' ]]; then
			systemctl reboot
		elif [[ $1 == '--suspend' ]]; then
			mpc -q pause
			amixer set Master mute
			systemctl suspend
		elif [[ $1 == '--logout' ]]; then
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
		fi
	else
		exit 0
	fi
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

# Actions
# Bare s/l/r (bound above via -kb-custom-N) act like picking that item and
# pressing Enter — same confirmation flow, just without navigating the
# list first. Lock has no confirmation step, same as selecting it normally.
chosen="$(run_rofi)"
rc=$?
case $rc in
	10) run_cmd --shutdown; exit 0 ;;
	11) do_lock; exit 0 ;;
	12) run_cmd --reboot; exit 0 ;;
esac

case ${chosen} in
    $shutdown)
		run_cmd --shutdown
        ;;
    $reboot)
		run_cmd --reboot
        ;;
    $lock)
		do_lock
        ;;
    $suspend)
		run_cmd --suspend
        ;;
    $logout)
		run_cmd --logout
        ;;
esac
