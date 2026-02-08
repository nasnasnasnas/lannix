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

    xdg.configFile."niri/config.kdl".source = ./niri.kdl;
    programs.fish.enable = true;
    programs.git = {
      enable = true;
      signing = {
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII/tUwFHraeGdHJFOpus9CmYKOVNulm6OeZlD5VBJfjF";
        format = "ssh";
        signByDefault = true;
        signer = "/run/current-system/sw/bin/op-ssh-sign";
      };
      settings.user = {
        name = "leah";
        email = "catgirl@catgirlin.space";
      };
    };
  };
}
