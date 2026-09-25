{inputs, ...}: let
  username = "leah";
in {
  flake.modules.homeManager."${username}" = {pkgs, ...}: {
    nix.registry = {
      nixpkgs-unstable.flake = inputs.nixpkgs-unstable;
      nixpkgs-master.flake = inputs.nixpkgs-master;
    };

    programs.fish.functions = {
      ns = {
        description = "Open a package shell from nixpkgs";
        body = ''
          set -l packages

          for package in $argv
            set -a packages "nixpkgs#$package"
          end

          NIXPKGS_ALLOW_UNFREE=1 nix shell --impure $packages
        '';
      };

      nsu = {
        description = "Open a package shell from nixpkgs unstable";
        body = ''
          set -l packages

          for package in $argv
            set -a packages "nixpkgs-unstable#$package"
          end

          NIXPKGS_ALLOW_UNFREE=1 nix shell --impure $packages
        '';
      };

      nsm = {
        description = "Open a package shell from nixpkgs master";
        body = ''
          set -l packages

          for package in $argv
            set -a packages "nixpkgs-master#$package"
          end

          NIXPKGS_ALLOW_UNFREE=1 nix shell --impure $packages
        '';
      };
    };
  };
}
