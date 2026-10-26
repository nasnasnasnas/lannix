{inputs, ...}: {
  flake.modules.nixos.opnix = {
    key = "lannix/opnix/nixos";
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
