{inputs, ...}: let
  username = "nea";
in {
  flake.modules.homeManager."${username}" = {...}: {
    programs.starship = {
      enable = true;
      presets = ["catppuccin-powerline"];
      settings = {
        palette = "catppuccin_macchiato";
        cmd_duration.show_notifications = false;
      };
    };
  };
}
