#!/usr/bin/env bash
# usbcrypt — unlock + mount + lock encrypted USB drives

usbo() {
    dev="$1"

    if [[ -z "$dev" ]]; then
        echo "Usage: usbo /dev/sdX1"
        return 1
    fi

    echo "[usbcrypt] unlocking $dev..."
    unlock_out=$(udisksctl unlock -b "$dev")

    dm=$(echo "$unlock_out" | awk '{print $NF}' | tr -d '.')

    echo "[usbcrypt] mounting /dev/$dm..."
    mount_out=$(udisksctl mount -b "/dev/$dm")

    path=$(echo "$mount_out" | sed 's/.*at //')

    echo "[usbcrypt] mounted at $path"

    # optional: open file manager
    dolphin "$path" >/dev/null 2>&1 &
}

usbc() {
    dev="$1"

    if [[ -z "$dev" ]]; then
        echo "Usage: usbc /dev/sdX1"
        return 1
    fi

    echo "[usbcrypt] unmounting..."
    dm=$(lsblk -ln -o NAME "$dev" | tail -n 1)

    udisksctl unmount -b "/dev/$dm"
    udisksctl lock -b "$dev"

    echo "[usbcrypt] locked $dev"
}
