{ inputs, ... }: {
  flake.modules.darwin.iris-homebrew = {
    imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];
    nix-homebrew = {
      enable = true;
      enableRosetta = true;
      user = "lavender";
      autoMigrate = true;
      taps = {
        "homebrew/homebrew-core" = inputs.homebrew-core;
        "homebrew/homebrew-cask" = inputs.homebrew-cask;
      };
      mutableTaps = false;
    };
  };
}
