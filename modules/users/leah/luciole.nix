{
  inputs,
  self,
  ...
}:
let
  username = "leah";
in
{
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
    environment.pathsToLink = [
      "/share/xdg-desktop-portal"
      "/share/applications"
    ];

    xdg.portal = {
      enable = true;
      # Home Manager's discovery path must retain the host's other backends.
      extraPortals = [
        inputs.luciole.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
      config = {
        common."org.freedesktop.impl.portal.FileChooser" = [
          "luciole"
          "gtk"
        ];
        niri."org.freedesktop.impl.portal.FileChooser" = [
          "luciole"
          "gtk"
        ];
      };
    };
  };

  flake.modules.homeManager."${username}-linux" =
    { pkgs, osConfig, ... }:
    {
      imports = [ inputs.luciole.homeModules.default ];

      xdg.portal = {
        enable = true;
        # Home Manager's discovery path must retain the host's other backends.
        extraPortals = [
          inputs.luciole.packages.${pkgs.stdenv.hostPlatform.system}.default
        ]
        ++ osConfig.xdg.portal.extraPortals;
        configPackages = osConfig.xdg.portal.configPackages;
        config = {
          common."org.freedesktop.impl.portal.FileChooser" = [
            "luciole"
            "gtk"
          ];
          niri."org.freedesktop.impl.portal.FileChooser" = [
            "luciole"
            "gtk"
          ];
        };
      };

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
