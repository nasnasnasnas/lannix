{inputs, ...}: let
  username = "leah";
in {
  flake.modules.homeManager."${username}" = {pkgs, ...}: {
    programs.ghostty = {
      enable = true;
      settings = {
        background-opacity = 0.75;
      };
    };
  };

  flake.modules.homeManager."${username}-linux" = {
    programs.ghostty.settings.theme = "noctalia";
  };

  flake.modules.homeManager."${username}-darwin" = {
    programs.ghostty.package = null;
  };
}