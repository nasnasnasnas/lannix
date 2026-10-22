{...}: let
  lix = {pkgs, ...}: {
    nix.package = pkgs.lixPackageSets.stable.lix;
  };
in {
  flake.modules.nixos.lix = lix;
  flake.modules.darwin.lix = lix;
}
