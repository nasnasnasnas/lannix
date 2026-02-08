{
  inputs,
  ...
}: let
  username = "leah";
in {
  flake.modules.homeManager."${username}" = {pkgs, lib, ...}: {
    programs.starship = {
      enable = true;
      settings = lib.mkMerge [
        (fromTOML (
          builtins.readFile "${pkgs.starship}/share/starship/presets/catppuccin-powerline.toml"
        ))
        {
          # here goes my custom configurations
          palette = lib.mkForce "catppuccin_macchiato";
          cmd_duration.show_notifications = lib.mkForce false;
        }
      ];
    };
  };
}
