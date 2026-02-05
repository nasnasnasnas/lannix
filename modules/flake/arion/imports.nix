{inputs, ...}: {
  flake-file.inputs = {
    arion = {
      url = "github:hercules-ci/arion";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # imports = [ inputs.arion.flakeModules.arion ];
}
