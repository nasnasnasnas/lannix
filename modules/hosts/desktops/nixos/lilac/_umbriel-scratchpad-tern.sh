# --control starts an independent frontend instead of forwarding the launch to
# an existing Tern process. It preserves Umbriel's activation token, placing the
# new window in the scratchpad before it can enter the workspace's tiled layout.
# Keep the automation socket private and unique while retaining normal Tern settings.
control_dir=$(mktemp -d "$XDG_RUNTIME_DIR/tern-scratchpad.XXXXXX")
trap 'rm -rf -- "$control_dir"' EXIT
tern --control "$control_dir/control.sock" "$HOME"
