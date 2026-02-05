# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  outputs = inputs: inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./modules);

  inputs = {
    arion = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:hercules-ci/arion";
    };
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    flake-file.url = "github:vic/flake-file";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager/release-25.11";
    };
    home-manager-unstable = {
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      url = "github:nix-community/home-manager/master";
    };
    homebrew-cask = {
      flake = false;
      url = "github:homebrew/homebrew-cask";
    };
    homebrew-core = {
      flake = false;
      url = "github:homebrew/homebrew-core";
    };
    import-tree.url = "github:vic/import-tree";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    nix-darwin = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    noctalia = {
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      url = "github:noctalia-dev/noctalia-shell";
    };
    winapps = {
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      url = "github:winapps-org/winapps";
    };
    zen-browser = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:0xc000022070/zen-browser-flake";
    };
  };
}
