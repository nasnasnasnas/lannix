# --control starts an independent frontend instead of forwarding the launch to
# an existing Tern process. It preserves Umbriel's activation token, placing the
# new window in the scratchpad before it can enter the workspace's tiled layout.
control_dir=$(mktemp -d "$XDG_RUNTIME_DIR/tern-scratchpad.XXXXXX")
trap 'rm -rf -- "$control_dir"' EXIT

# The first frontend after logout restores the daemon's primary window and its
# sessions. Never let the scratchpad claim it: restore regular Tern first, without
# any scratchpad placement token, and wait until it owns the primary window.
primary_attached() {
    tern inspect --json 2>/dev/null |
        jq -e '.clients | any(.kind == "window" and .window == "")' >/dev/null
}
if ! primary_attached; then
    env -u XDG_ACTIVATION_TOKEN -u DESKTOP_STARTUP_ID -u UMBRIEL_LAUNCH_TOKEN \
        tern --control "$control_dir/regular.sock" &
    regular_pid=$!
    for ((attempt = 0; attempt < 100; attempt++)); do
        if primary_attached; then
            break
        fi
        if ! kill -0 "$regular_pid" 2>/dev/null; then
            echo "Regular Tern exited before restoring its primary window; not opening scratchpad." >&2
            exit 1
        fi
        sleep 0.1
    done
    if ! primary_attached; then
        echo "Timed out restoring regular Tern; not opening scratchpad." >&2
        exit 1
    fi
fi
tern --control "$control_dir/control.sock" "$HOME"
