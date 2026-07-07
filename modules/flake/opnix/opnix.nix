{inputs, ...}: {
  flake.modules.nixos.opnix = {
    # Deduplicates when several modules import opnix on the same host.
    key = "lannix/opnix";
    imports = [
      inputs.opnix.nixosModules.default
    ];
  };
  flake.modules.darwin.opnix = {
    imports = [
      inputs.opnix.darwinModules.default
    ];
  };
}
