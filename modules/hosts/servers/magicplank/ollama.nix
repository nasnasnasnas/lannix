{inputs, ...}: {
  flake.modules.nixos.magicplank = {pkgs, ...}: {
    services.ollama.enable = true;
    services.ollama.package = pkgs.unstable.ollama-rocm;
    services.ollama.host = "0.0.0.0";
    services.ollama.loadModels = [
      "gemma4:e2b-it-qat"
      "gemma4:e4b-it-qat"
      "gemma4:12b-it-qat"
      "gemma4:26b-a4b-it-qat"
      "gemma4:31b-it-qat"
    ];
    services.ollama.environmentVariables = {
      OLLAMA_JINA = "true";
    };
    networking.firewall.allowedTCPPorts = [11434];
  };
}
