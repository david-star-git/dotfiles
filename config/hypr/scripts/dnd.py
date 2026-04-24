#!/usr/bin/env python3
"""
dnd.py - DND mode toggle for waybar + mako
Modes:
  off    - normal notifications  (makoctl mode: default)
  dnd    - hide all except critical (makoctl mode: default dnd)
  ultra  - hide everything         (makoctl mode: default ultra)
Left click  (--toggle) cycles: off → dnd → off
Right click (--ultra)  cycles: off/dnd → ultra → off
Always keep "default" in the mode list so mako's built-in
defaults (grouped format, etc.) continue to apply.
"""

import subprocess, sys, os
STATE_FILE = os.path.expanduser("~/.cache/dnd-mode")
ICONS = {
    "off": "󰂚",
    "dnd": "󰂛",
    "ultra": "󰪑",
}


def get_mode():
    try:
        return open(STATE_FILE).read().strip()
    except FileNotFoundError:
        return "off"


def set_mode(mode):
    open(STATE_FILE, "w").write(mode)
    # Always keep "default" in the list alongside our custom mode
    if mode == "off":
        modes = ["default"]
    else:
        modes = ["default", mode]
    subprocess.run(["makoctl", "mode", "-s"] + modes)


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else "--status"
    mode = get_mode()
    if arg == "--status":
        # Always print something so waybar never shows a blank
        print(ICONS.get(mode, ICONS["off"]), flush=True)
    elif arg == "--toggle":
        if mode == "dnd":
            set_mode("off")
        elif mode == "ultra":
            set_mode("off")
        else:
            set_mode("dnd")
    elif arg == "--ultra":
        if mode == "ultra":
            set_mode("off")
        else:
            set_mode("ultra")
if __name__ == "__main__":
    main()

