#!/usr/bin/env bash
# cpu — print current CPU usage as a percentage
# used by the zsh prompt and callable standalone
grep 'cpu ' /proc/stat \
    | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}' \
    | awk '{printf("%.1f\n", $1)}'
