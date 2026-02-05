{inputs, ...}: {
  flake-file.inputs = {
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # imports = [ inputs.nix-darwin.flakeModules.nix-darwin ];
}
