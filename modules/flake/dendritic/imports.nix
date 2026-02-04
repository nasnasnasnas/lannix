{ inputs, ... }:
{
  # imports = [
  #   inputs.flake-file.flakeModules.dendritic
  # ];
   flake-file.inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-file.url = "github:vic/flake-file";
    import-tree.url = "github:vic/import-tree";
  };

  imports = [
    inputs.flake-parts.flakeModules.modules
    inputs.flake-file.flakeModules.default
  ];

  # import all modules recursively with import-tree
  flake-file.outputs = ''
    inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules)
  '';

  # set flake.systems
  systems = [
    "aarch64-darwin"
    "aarch64-linux"
    "x86_64-darwin"
    "x86_64-linux"
  ];
}
