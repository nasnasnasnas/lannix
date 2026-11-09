{ inputs, ... }: {
  # Host-local files contribute directly to magicplank; imports select shared features.
  flake.modules.nixos.magicplank = {
    imports = with inputs.self.modules.nixos; [
      lavender-server
      server-shared-workspace
    ];
    system.stateVersion = "25.05";
  };
}
