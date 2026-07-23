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
  flake.modules.homeManager."${username}-linux" = {
    xdg.configFile."niri/config.kdl".source = ./niri.kdl;
  };
}
