{ inputs, ... }: {
  flake.modules.nixos.nea-desktop = {
    imports = [ inputs.self.modules.nixos.tern ];
  };
}
