{inputs, ...}: {
  flake-file.inputs = {
    arion = {
      url = "github:hercules-ci/arion";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      # IMPORTANT: we're using "libgbm" and is only available in unstable so ensure
      # to have it up-to-date or simply don't specify the nixpkgs input
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    winapps = {
      url = "github:winapps-org/winapps";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
  };

  # imports = [
  #   inputs.arion.flakeModules.arion
  #   inputs.zen-browser.flakeModules.zen-browser
  #   inputs["nix-flatpak"].flakeModules.nix-flatpak
  #   inputs.noctalia.flakeModules.noctalia-shell
  #   inputs.winapps.flakeModules.winapps
  #   inputs["nix-cachyos-kernel"].flakeModules.nix-cachyos-kernel
  #   inputs.nixos-hardware.flakeModules.nixos-hardware
  # ];
}
