{ inputs, ... }: {
  flake.modules.darwin.iris = {
    imports = with inputs.self.modules.darwin; [
      lavender
      nea
      iris-homebrew
    ];
    system.primaryUser = "lavender";
    system.stateVersion = 6;
  };
}
