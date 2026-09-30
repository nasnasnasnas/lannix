{inputs, ...}: let
  username = "leah";
in {
  flake.modules.homeManager."${username}" = {pkgs, ...}: {
    programs.hyfetch = {
      enable = true;
      settings = {
        preset = "plural";
        color_align = {
          mode = "horizontal";
        };
        
      };
    };
  };
}