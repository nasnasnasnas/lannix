{
  inputs,
  self,
  ...
}: let
  username = "leah";
in {
  flake-file.inputs = {
    luciole = {
      url = "github:noctalia-dev/luciole";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
      };
    };
  };

  flake.modules.nixos."${username}" = {pkgs, ...}: {
    services.gvfs.enable = true;
  };

  flake.modules.homeManager."${username}-linux" = {pkgs, ...}: {
    imports = [ inputs.luciole.homeModules.default ];

    programs.luciole = {
      enable = true;
      checkConfig = true;
      settings = {
        browser = {
          view_mode = "grid";
          show_hidden = false;
        };
      };
    };
  };
}