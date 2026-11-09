{ inputs, ... }: {
  flake.modules.nixos.lilac-tern = {
    imports = [ inputs.self.modules.nixos.tern ];
  };
}
