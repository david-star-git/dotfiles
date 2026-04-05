#!/bin/bash
# mcp — mass copy with template-based renaming
#
# Copies files matching a source pattern to destinations derived from a
# destination pattern. Both patterns use {variable} placeholders.
# Uppercase versions of every variable are also available as {VARIABLE}.
#
# Usage:
#   mcp <src_template> <dst_template>
#
# Example:
#   mcp '{name}-xyz-{src}.*' '{src}/{NAME}-ABC.txt'
#
#   Given files:  foo-xyz-bar.txt  baz-xyz-qux.log
#   Produces:     bar/FOO-ABC.txt  qux/BAZ-ABC.txt
#
# Requires: jq, python3

src_template="$1"
dst_template="$2"

# Convert the source template into a shell glob by replacing every
# {placeholder} with a wildcard so we can iterate matching files.
glob_pattern=$(echo "$src_template" | sed -E 's/\{[^}]+\}/\*/g')

shopt -s nullglob
for src_file in $glob_pattern; do

    # Build a named-capture-group regex from the source template so we can
    # extract the actual values of each placeholder from the filename.
    regex="^$src_template$"
    regex=$(echo "$regex" \
        | sed -E 's/\./\\./g' \
        | sed -E 's/\{([a-zA-Z_][a-zA-Z0-9_]*)\}/(?P<\1>[^\/]*)/g')

    # Run Python to do the regex match and return captures as JSON.
    vars=$(python3 -c "
import re, json
m = re.match(r'''$regex''', '''$src_file''')
print(json.dumps(m.groupdict()) if m else '')
")

    [[ -z "$vars" ]] && continue   # no match — skip this file

    # Load each captured variable into shell as var_<name>
    eval $(echo "$vars" | jq -r 'to_entries|map("var_\(.key)=\"\(.value)\"")|.[]')

    # Also create uppercase versions: var_NAME, var_SRC, etc.
    for k in $(echo "$vars" | jq -r 'keys[]'); do
        eval "var_$(echo $k | tr a-z A-Z)=\"\${var_$k^^}\""
    done

    # Substitute all {var} and {VAR} occurrences in the destination template.
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
