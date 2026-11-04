# Reuse Tern for tabs, as niri-tern does, but focus through Umbriel IPC.
tern_bin=/run/current-system/sw/bin/tern
if [ "${1:-tab}" = window ]; then
    exec "$tern_bin"
fi
window_id=$(umbriel windows --json | jq -r '[.[] | select(.app_id == "so.stencil.tern")][0].id // empty')
if [ -z "$window_id" ]; then
    exec "$tern_bin"
fi
if created=$("$tern_bin" new tab --cwd "$HOME" --json); then
    block_id=$(printf '%s\n' "$created" | jq -er '.block')
    # Preserve the Fish login-shell workaround used by niri-tern.
    if "$tern_bin" wait "$block_id" --until prompt --timeout 10; then
        "$tern_bin" send "$block_id" text "$(printf 'exec /run/current-system/sw/bin/fish -l\r')"
    fi
    "$tern_bin" focus "$block_id"
    umbriel msg window-focus "$window_id"
else
    exec "$tern_bin"
fi
