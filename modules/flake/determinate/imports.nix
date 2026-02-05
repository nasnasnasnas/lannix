{inputs, ...}: {
  flake-file.inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
  };

  # imports = [ inputs.determinate.flakeModules.determinate ];
}
