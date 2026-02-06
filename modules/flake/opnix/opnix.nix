{inputs, ...}: {
  flake.modules.nixos.opnix = {
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
