{ self, lib, ... }:

let
  filterBroken = _: lib.filterAttrs (n: v: v ? meta -> v.meta ? broken -> !v.meta.broken);

  getTopLevel = (name: { toplevel = self.nixosConfigurations.${name}.config.system.build.toplevel; });
in
{
  flake.hydraJobs = {
    packages = lib.mapAttrs filterBroken { inherit (self.packages) x86_64-linux; };
    nixosConfigurations.x86_64-linux = lib.flip lib.genAttrs getTopLevel [
      "lilac"
      "magicplank"
      "magicbox"
      "remotebox"
      "nea-desktop"
    ];
  };
}
