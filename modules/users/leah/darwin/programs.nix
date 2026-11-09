{ ... }: {
  flake.modules.darwin.lavender = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      _1password-gui
      tailscale-gui
    ];
  };
  flake.modules.homeManager.leah-desktop-darwin = { pkgs, ... }: {
    home.packages = with pkgs; [
      unstable.obsidian
      unstable.vscode
      prismlauncher
      vesktop
      unstable.jetbrains.webstorm
      unstable.jetbrains.idea
      unstable.jetbrains.rust-rover
    ];
  };
}
