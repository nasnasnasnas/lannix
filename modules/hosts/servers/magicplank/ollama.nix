{inputs, ...}: {
  flake.modules.nixos.magicplank = {pkgs, ...}: {
    services.ollama.enable = true;
    services.ollama.package = pkgs.unstable.ollama-rocm;
    services.ollama.loadModels = [
      "gemma4:e2b"
      "gemma4:e4b"
      "gemma4:12b"
      "gemma4:26b"
      "gemma4:31b"
    ];
  };
}
