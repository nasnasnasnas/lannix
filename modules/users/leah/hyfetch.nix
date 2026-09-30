{inputs, ...}: let
  username = "leah";
in {
  flake.modules.homeManager."${username}" = {pkgs, ...}: {
    programs.fastfetch.enable = true;
    programs.hyfetch = {
      enable = true;
      settings = {
        preset = "plural";
        color_align = {
          mode = "horizontal";
        };
        mode = "rgb";
        backend = "fastfetch";
        pride_month_disable = false;
      };
    };
  };
}