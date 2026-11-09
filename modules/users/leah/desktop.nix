{ inputs, ... }: {
  flake.modules.homeManager.leah-desktop = { pkgs, ... }: {
    programs.git.signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII/tUwFHraeGdHJFOpus9CmYKOVNulm6OeZlD5VBJfjF";
      format = "ssh";
      signByDefault = true;
      signer =
        if pkgs.stdenv.isDarwin then
          "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
        else
          "/run/current-system/sw/bin/op-ssh-sign";
    };
  };
  flake.modules.homeManager.leah-desktop-darwin = {
    imports = [ inputs.self.modules.homeManager.leah-desktop ];
  };
  flake.modules.homeManager.leah-desktop-linux = { pkgs, ... }: {
    imports = [ inputs.self.modules.homeManager.leah-desktop ];
    # Tern uses Zenity for close-confirmation dialogs on Linux.
    home.packages = [ pkgs.zenity ];
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
