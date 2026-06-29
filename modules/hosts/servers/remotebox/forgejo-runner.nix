{inputs, ...}: {
  flake.modules.nixos.remotebox = {pkgs, ...}: {
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
      after = ["opnix-secrets.service"];
      requires = ["opnix-secrets.service"];
      before = ["gitea-runner-forgejo.service"];
      wantedBy = ["gitea-runner-forgejo.service"];
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
        name = "forgejo-runner-remotebox";
        tokenFile = "/var/lib/opnix/secrets/forgejo-runner/token-env";
        url = "https://git.szpunar.cloud/";
        labels = [
          "remotebox-native:host"
        ];
        hostPackages = with pkgs; [
          bash coreutils curl gawk git gnused nodejs wget nix attic-client nix-fast-build jq openssh nixos-rebuild
        ];
        settings = {
          runner.capacity = 2;
        };
      };
    };
  };
}
