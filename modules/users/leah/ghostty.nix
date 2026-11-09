{ inputs, ... }:
let
  username = "leah";
in
{
  flake.modules.homeManager.leah-desktop = { pkgs, ... }: {
    programs.ghostty = {
      enable = true;
      settings = {
        background-opacity = 0.65;
      };
    };
  };

  flake.modules.homeManager.leah-desktop-linux = {
    programs.ghostty.settings.theme = "noctalia";
  };

  flake.modules.homeManager.leah-desktop-darwin = { pkgs, ... }: {
    programs.ghostty.package = pkgs.ghostty-bin;
  };
}
