# Tern's existing process does not forward Umbriel's activation token to new
# windows. Identify the newly mapped Tern window rather than moving an old one.
before=$(umbriel windows --json | jq '[.[] | select(.app_id == "so.stencil.tern") | .id]')
if [ "$before" = '[]' ]; then
    # A fresh Tern process receives the launch token directly.
    exec tern "$HOME"
fi
tern "$HOME" &
for ((attempt = 0; attempt < 100; attempt++)); do
    window=$(umbriel windows --json | jq -c --argjson before "$before" '
        first(.[] | select(.app_id == "so.stencil.tern")
            | select(.id as $id | $before | index($id) | not)) // empty')
    if [ -n "$window" ]; then
        id=$(jq -r '.id' <<< "$window")
        if [ "$(jq -r '.scratchpad' <<< "$window")" != terminal ]; then
            umbriel msg window-focus "$id"
            umbriel msg window-toggle-scratchpad terminal
            umbriel msg window-focus "$id"
        fi
        exit 0
    fi
    sleep 0.1
done
printf '%s\n' 'Tern did not map a new window for the scratchpad within 10 seconds' >&2
exit 1
