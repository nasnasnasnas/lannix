# Add tabs to Tern's primary window, never the secondary scratchpad window.
# Focus through Umbriel IPC, excluding windows currently stored in a pad.
tern_bin=/run/current-system/sw/bin/tern
if [ "${1:-tab}" = window ]; then
    exec "$tern_bin"
fi
window_id=$(umbriel windows --json | jq -r '[.[] | select(.app_id == "so.stencil.tern" and .scratchpad == "")][0].id // empty')
if [ -z "$window_id" ]; then
    exec "$tern_bin"
fi
if created=$("$tern_bin" new tab --window "" --cwd "$HOME" --json); then
    block_id=$(printf '%s\n' "$created" | jq -er '.block')
    # Preserve the Fish login-shell workaround used by niri-tern.
    if "$tern_bin" wait "$block_id" --window "" --until prompt --timeout 10; then
        "$tern_bin" send "$block_id" --window "" text "$(printf 'exec /run/current-system/sw/bin/fish -l\r')"
    fi
    "$tern_bin" focus "$block_id" --window ""
    umbriel msg window-focus "$window_id"
else
    exec "$tern_bin"
fi
