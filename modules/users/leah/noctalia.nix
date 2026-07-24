{inputs, ...}: let
  username = "leah";
in {
  flake.modules.homeManager."${username}-linux" = {
    lib,
    pkgs,
    ...
  }: {
    imports = [
      inputs.noctalia.homeModules.default
    ];

    home.packages = [pkgs.noctalia-config-sync];

    programs.noctalia.enable = true;
    programs.noctalia.validateConfig = true;
    programs.noctalia.settings = lib.recursiveUpdate (import ./_noctalia-config.nix) {
      shell.avatar_path = ./pfp.jpg;
      wallpaper.default.path = ./nas-flag-wallpaper.png;
    };
  };
}
