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
        body = "nix shell nixpkgs#$argv";
      };

      nsu = {
        description = "Open a package shell from nixpkgs unstable";
        body = "nix shell nixpkgs-unstable#$argv";
      };

      nsm = {
        description = "Open a package shell from nixpkgs master";
        body = "nix shell nixpkgs-master#$argv";
      };
    };
  };
}
