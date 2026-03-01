{inputs, ...}: {
  flake.modules.nixos.magicplank = {pkgs, config, ...}: {
    imports = [ inputs.self.modules.nixos.opnix ];
    services.onepassword-secrets = {
      enable = true;
      tokenFile = "/etc/opnix-token";
      secrets = {
        forgejoRunnerToken = {
          path = "/var/lib/opnix/secrets/forgejo-runner/token";
          reference = "op://Secrets/Forgejo Runner Registration Token/password";
          owner = 1001;
          group = 1001;
        };
      };
    };

    services.gitea-actions-runner = {
      package = pkgs.forgejo-runner;
      instances.forgejo-instance = {
        enable = true;
        name = "forgejo-runner-magicplank";
        tokenFile = config.services.onepassword-secrets.secretPaths.forgejoRunnerToken;
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
