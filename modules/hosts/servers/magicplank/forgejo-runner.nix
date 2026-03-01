{inputs, ...}: {
  flake.modules.nixos.magicplank = {pkgs, ...}: {
    services.onepassword-secrets = {
      enable = true;
      secrets = {
        forgejoRunnerToken = {
          path = "/var/lib/opnix/secrets/forgejo-runner/token";
          reference = "op://Secrets/Forgejo Runner Registration Token/password";
          mode = "0640";
        };
      };
    };

    system.activationScripts.forgejo-runner-token-env = {
      deps = [ "opnix-secrets" ];
      text = ''
        install -Dm 0640 /dev/null /var/lib/opnix/secrets/forgejo-runner/token-env
        echo "TOKEN=$(cat /var/lib/opnix/secrets/forgejo-runner/token)" \
          > /var/lib/opnix/secrets/forgejo-runner/token-env
      '';
    };

    services.gitea-actions-runner = {
      package = pkgs.forgejo-runner;
      instances.forgejo-instance = {
        enable = true;
        name = "forgejo-runner-magicplank";
        tokenFile = "/var/lib/opnix/secrets/forgejo-runner/token-env";
        url = "https://git.szpunar.cloud/";
        labels = [
          "node-22:docker://node:22-bookworm"
          "nixos-latest:docker://nixos/nix"
          "bun-latest:docker://oven/bun:latest"
        ];
        # settings = { ... };
      };
    };
  };
}
