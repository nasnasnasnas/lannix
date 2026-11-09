{ inputs, ... }: {
  flake.modules.nixos.magicplank = {
    imports = with inputs.self.modules.nixos; [
      magicplank-platform
      magicplank-hardware
      magicplank-services
      magicplank-forgejo-runner
      magicplank-backup
      magicplank-steam
      magicplank-samba
      magicplank-ollama
      magicplank-journal-sentiment
      magicplank-observability-auth
      lavender-server
      server-shared-workspace
    ];
    system.stateVersion = "25.05";
  };
}
