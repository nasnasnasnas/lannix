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

    systemd.services.forgejo-runner-token-env = {
      description = "Prepare forgejo runner token env file";
      after = [ "opnix-secrets.service" ];
      requires = [ "opnix-secrets.service" ];
      before = [ "gitea-runner-forgejo.service" ];
      wantedBy = [ "gitea-runner-forgejo.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "forgejo-runner-token-env" ''
          install -Dm 0640 /dev/null /var/lib/opnix/secrets/forgejo-runner/token-env
          printf 'TOKEN=%s' "$(cat /var/lib/opnix/secrets/forgejo-runner/token)" \
            > /var/lib/opnix/secrets/forgejo-runner/token-env
        '';
      };
    };

    services.gitea-actions-runner = {
      package = pkgs.forgejo-runner;
      instances.forgejo = {
        enable = true;
        name = "forgejo-runner-magicplank";
        tokenFile = "/var/lib/opnix/secrets/forgejo-runner/token-env";
        url = "https://git.szpunar.cloud/";
        labels = [
          "node-22:docker://node:22-bookworm"
          "nixos-latest:docker://nixos/nix"
          "bun-latest:docker://oven/bun:latest"
          "debian-latest:docker://debian:latest"
          "ubuntu-latest:docker://ubuntu:latest"
        ];
        # settings = { ... };
      };
    };
  };
}
