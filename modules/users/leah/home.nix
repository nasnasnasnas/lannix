{inputs, ...}: let
  username = "leah";
in {
  flake.modules.homeManager."${username}" = {pkgs, ...}: {
    imports = with inputs.self.modules.homeManager; [
      default-settings
    ];
    home.username = "${username}";
    home.packages = with pkgs; [
      htop
    ];

    programs.fish.enable = true;
    programs.eza = {
      enable = true;
      enableFishIntegration = true;
      icons = "auto";
    };
    programs.git = {
      enable = true;
      signing = {
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII/tUwFHraeGdHJFOpus9CmYKOVNulm6OeZlD5VBJfjF";
        format = "ssh";
        signByDefault = true;
        signer =
          if pkgs.stdenv.isDarwin
          then "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
          else "/run/current-system/sw/bin/op-ssh-sign";
      };
      settings.user = {
        name = "leah";
        email = "catgirl@catgirlin.space";
      };
    };
  };

  # linux-only home manager bits (niri, noctalia, ...); imported by the nixos
  # user module in configuration.nix but left out of the darwin one
  flake.modules.homeManager."${username}-linux" = {pkgs, ...}: {
    # Tern uses Zenity for close-confirmation dialogs on Linux.
    home.packages = [pkgs.zenity];
    programs.fish.interactiveShellInit = ''
      # Tern passes WAYLAND_DISPLAY to new shells but drops NIRI_SOCKET.
      if not set -q NIRI_SOCKET
        set -l niri_socket (${pkgs.systemd}/bin/systemctl --user show-environment 2>/dev/null \
          | string replace --filter --regex '^NIRI_SOCKET=' "")
        if test -S "$niri_socket"
          set -gx NIRI_SOCKET "$niri_socket"
        end
      end
    '';
    xdg.configFile."niri/config.kdl".source = ./niri.kdl;
    home.file.".local/bin/niri-tern" = {
      source = ./niri-tern.sh;
      executable = true;
    };
  };
}
