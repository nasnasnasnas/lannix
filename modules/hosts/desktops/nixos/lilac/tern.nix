{ inputs, ... }: {
  flake.modules.nixos.lilac = {
    imports = [ inputs.self.modules.nixos.tern ];
  };
}
