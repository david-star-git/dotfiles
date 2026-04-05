#!/bin/bash
# merge — merge and deduplicate text files
#
# Concatenates two or more files, sorts all lines, removes duplicates,
# and writes the result to an output file. Progress is shown via pv.
#
# Usage:
#   merge file1 file2 [file3 ...] [-o output_file]
#
# Options:
#   -o <file>   output filename (default: output.txt)
#
# Requires: pv (progress viewer)

outfile="output.txt"
files=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o)
            shift
            if [[ -z "$1" ]]; then
                echo "Error: -o requires a filename"
                exit 1
            fi
            outfile="$1"
            shift
            ;;
        *)
            files+=("$1")
            shift
            ;;
    esac
done

if [[ ${#files[@]} -lt 2 ]]; then
    echo "Usage: merge file1 file2 [file3 ...] [-o output_file]"
    exit 1
fi

# Count total lines across all input files so pv can show a meaningful ETA.
total_lines=0
for f in "${files[@]}"; do
    if [[ -f "$f" ]]; then
        total_lines=$((total_lines + $(wc -l < "$f")))
    else
        echo "Warning: '$f' is not a file, skipping."
    fi
done

if [[ $total_lines -eq 0 ]]; then
    echo "No lines to process."
    exit 1
fi

# Concatenate → progress bar → sort → deduplicate → write output
cat "${files[@]}" | pv -l -s "$total_lines" | sort | uniq > "$outfile"

echo
echo "Merged ${#files[@]} files into '$outfile' with duplicates removed."
