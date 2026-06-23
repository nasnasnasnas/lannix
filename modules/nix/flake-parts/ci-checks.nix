{config, lib, ...}: {
  perSystem = {system, ...}: {
    checks =
      lib.mapAttrs'
      (name: cfg: lib.nameValuePair "toplevel-${name}" cfg.config.system.build.toplevel)
      (lib.filterAttrs
        (_: cfg: cfg.config.nixpkgs.hostPlatform.system == system)
        config.flake.nixosConfigurations);
  };
}
