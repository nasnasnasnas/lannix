{inputs, ...}: let
  username = "leah";
in {
  flake.modules.homeManager."${username}" = {pkgs, ...}: {
    programs.ghostty = {
      enable = true;
      settings = {
        background-opacity = 0.7;
      };
    };
  };
}