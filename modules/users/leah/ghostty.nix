{inputs, ...}: let
  username = "leah";
in {
  flake.modules.homeManager."${username}" = {pkgs, ...}: {
    programs.ghostty = {
      enable = true;
      settings = {
        background-opacity = 0.8;
      };
    };
  };

  flake.modules.homeManager."${username}-linux" = {
    programs.ghostty.settings.theme = "noctalia";
  };
}