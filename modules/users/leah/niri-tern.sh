#!/bin/sh
# Reuse Tern for tabs; a plain Tern launch always opens a new window.
tern_bin="${TERN_BIN:-/run/current-system/sw/bin/tern}"
if [ "${1:-tab}" = window ]; then
    exec "$tern_bin"
fi
window_id=$(niri msg windows | awk '
    /^Window ID / { id=$3; sub(/:$/, "", id) }
    /App ID: "so.stencil.tern"/ { print id; exit }
')
if [ -z "$window_id" ]; then
    exec "$tern_bin"
fi
if created=$("$tern_bin" new tab --cwd "$HOME" --json); then
    block_id=$(printf '%s\n' "$created" | awk '/"block":/ { gsub(/,/, "", $2); print $2; exit }')
    # The default Tern shell does not reliably load the configured Fish environment.
    # Replace it after the prompt so Tern still treats this as an idle shell.
    if "$tern_bin" wait "$block_id" --until prompt --timeout 10; then
        "$tern_bin" send "$block_id" text "$(printf 'exec /run/current-system/sw/bin/fish -l\r')"
    fi
    "$tern_bin" focus "$block_id"
    niri msg action focus-window --id "$window_id"
else
    exec "$tern_bin"
fi
