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

    virtualisation.arion.projects."forgejo-dind".settings.services."forgejo-dind".service = {
      restart = "unless-stopped";
      container_name = "forgejo-dind";
      image = "docker:dind";
      privileged = true;
      command = ["dockerd" "-H" "tcp://0.0.0.0:2375" "--tls=false"];
      ports = [ "127.0.0.1:2376:2375" ];
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
          "rust-latest:docker://rust:latest"
        ];
        settings = {
          runner = {
            capacity = 10;
            envs = {
              DOCKER_HOST = "tcp://forgejo-dind.docker.internal:2375";
            };
          };
          container = {
            docker_host = "tcp://127.0.0.1:2376";
            options = "--add-host=forgejo-dind.docker.internal:host-gateway";
          };
        };
      };
    };
  };
}
