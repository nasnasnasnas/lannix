{
  inputs,
  lib,
  ...
}: {
  # Helper functions for creating system / home-manager configurations

  options.flake.lib = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = {};
  };

  config.flake.lib = {
    mkNixos = system: name: {
      ${name} = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          inputs.self.modules.nixos.${name}
          inputs.self.modules.nixos.host-dns
          {nixpkgs.hostPlatform = lib.mkDefault system;}
          ({pkgs, ...}: {
            networking.hostName = name;

            # TODO: move these to somewhere that isn't here
            nix.settings.experimental-features = ["nix-command" "flakes" "pipe-operators"];
            nixpkgs.overlays = [
              (final: _prev: {
                unstable = import inputs.nixpkgs-unstable {
                  inherit (final) config;
                  system = pkgs.stdenv.hostPlatform.system;
                };
              })
            ];

            nixpkgs.config.allowUnfree = true;
            nixpkgs.config.nvidia.acceptLicense = true;
            nixpkgs.config.permittedInsecurePackages = [
              "olm-3.2.16"
            ];
          })
        ];
      };
    };

    mkDarwin = system: name: {
      ${name} = inputs.nix-darwin.lib.darwinSystem {
        modules = [
          inputs.self.modules.darwin.${name}
          {nixpkgs.hostPlatform = lib.mkDefault system;}
          ({...}: {networking.hostName = name;})
        ];
      };
    };

    mkHomeManager = system: name: {
      ${name} = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        modules = [
          inputs.self.modules.homeManager.${name}
          {nixpkgs.config.allowUnfree = true;}
        ];
      };
    };
  };
}
