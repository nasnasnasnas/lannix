{
  config,
  lib,
  ...
}: {
  perSystem = {system, ...}: let
    mkToplevelChecks = configurations:
      lib.mapAttrs'
      (name: cfg: lib.nameValuePair "toplevel-${name}" cfg.config.system.build.toplevel)
      (lib.filterAttrs
        (_: cfg: cfg.config.nixpkgs.hostPlatform.system == system)
        configurations);
  in {
    checks =
      mkToplevelChecks config.flake.nixosConfigurations
      // mkToplevelChecks config.flake.darwinConfigurations;
  };
}
