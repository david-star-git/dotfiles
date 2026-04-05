#!/usr/bin/env bash
# record — screen recorder using ffmpeg + VAAPI hardware encoding
#
# Usage:
#   record [--name|-n <name>] [--fps|-f <fps>] [--resolution|-r <WxH>]
#
# Defaults: name=recording  fps=60  resolution=1920x1080
# Output:   ~/Videos/ffmpeg/<timestamp>_<name>.mp4
#
# Detects the active window and records the monitor it lives on.
# Requires: ffmpeg, xdotool, xrandr

name="recording"
fps="60"
resolution="1920x1080"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --name|-n)      name="$2";       shift 2 ;;
        --fps|-f)       fps="$2";        shift 2 ;;
        --resolution|-r) resolution="$2"; shift 2 ;;
        *)
            # positional fallback — fill in order: name, fps, resolution
            if   [[ "$name"       == "recording" ]]; then name="$1"
            elif [[ "$fps"        == "60"        ]]; then fps="$1"
            elif [[ "$resolution" == "1920x1080" ]]; then resolution="$1"
            fi
            shift
            ;;
    esac
done

dir="$HOME/Videos/ffmpeg"
mkdir -p "$dir"

timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

# Get geometry of the currently active window
win=$(xdotool getactivewindow)
eval "$(xdotool getwindowgeometry --shell "$win")"

# Find which monitor the window's top-left corner sits on
monitor=$(xrandr --listmonitors | awk -v x="$X" -v y="$Y" '
    NR>1 {
        split($3, a, "+")
        split(a[1], res, "x")
        mx=a[2]; my=a[3]
        mw=res[1]; mh=res[2]
        if (x>=mx && x<mx+mw && y>=my && y<my+mh) {
            print mx","my
            exit
        }
    }')

[[ -z "$monitor" ]] && monitor="0,0"

echo "Recording $resolution @ ${fps}fps → $dir/${timestamp}_${name}.mp4"
echo "Press Ctrl+C to stop."

ffmpeg \
    -video_size   "$resolution" \
    -framerate    "$fps" \
    -f            x11grab \
    -i            ":0.0+$monitor" \
    -vaapi_device /dev/dri/renderD128 \
    -vf           'format=nv12,hwupload' \
    -c:v          h264_vaapi \
    "$dir/${timestamp}_${name}.mp4"
