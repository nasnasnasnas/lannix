{inputs, ...}: {
  flake-file.inputs = {
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # imports = [ inputs.nix-darwin.flakeModules.nix-darwin ];
}
