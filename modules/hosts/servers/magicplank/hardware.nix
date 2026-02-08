{inputs, ...}: {
  flake.modules.nixos.magicplank = {
    pkgs,
    modulesPath,
    ...
  }: {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
      inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    ];
  };
}
