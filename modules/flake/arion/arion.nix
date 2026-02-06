{inputs, ...}: {
  flake.modules.nixos.arion = {
    imports = [
      inputs.arion.nixosModules.arion
    ];
    virtualisation.arion = {
      backend = "docker";
    };
  };
}
