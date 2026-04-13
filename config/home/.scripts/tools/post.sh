#!/usr/bin/env bash
# post — resize all JPGs in the current directory to 2000×3000 for posting
# output files are prefixed with "resized_" and stripped of metadata
# requires: imagemagick (magick)
for f in *.jpg; do
    [[ -f "$f" ]] || continue
    magick "$f" -strip -resize 2000x3000 "resized_$f"
    echo "→ resized_$f"
done
