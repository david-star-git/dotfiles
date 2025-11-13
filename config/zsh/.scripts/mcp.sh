#!/bin/bash

# mcp '{name}-xyz-{src}.*' '{src}/{NAME}-ABC.txt'

src_template="$1"
dst_template="$2"

# Convert template to glob pattern
glob_pattern=$(echo "$src_template" | sed -E 's/\{[^}]+\}/\*/g')

shopt -s nullglob
for src_file in $glob_pattern; do
    # Build a regex from the src_template
    regex="^$src_template$"
    regex=$(echo "$regex" \
        | sed -E 's/\./\\./g' \
        | sed -E 's/\{([a-zA-Z_][a-zA-Z0-9_]*)\}/(?P<\1>[^\/]*)/g')

    # Use Python to extract variables with the regex
    vars=$(python3 -c "
import re, json
m = re.match(r'''$regex''', '''$src_file''')
print(json.dumps(m.groupdict()) if m else '')
")

    [[ -z "$vars" ]] && continue

    # Parse JSON output into shell variables
    eval $(echo "$vars" | jq -r 'to_entries|map("var_\(.key)=\"\(.value)\"")|.[]')

    # Uppercase variables
    for k in $(echo "$vars" | jq -r 'keys[]'); do
        eval "var_$(echo $k | tr a-z A-Z)=\"\${var_$k^^}\""
    done

    # Replace {var} and {VAR} in destination pattern
    dest="$dst_template"
    for k in $(echo "$vars" | jq -r 'keys[]'); do
        val=$(eval echo \$var_$k)
        uval=$(eval echo \$var_$(echo $k | tr a-z A-Z))
        dest=${dest//\{$k\}/$val}
        dest=${dest//\{${k^^}\}/$uval}
    done

    echo "Copying $src_file → $dest"
    mkdir -p "$(dirname "$dest")"
    cp "$src_file" "$dest"
done
