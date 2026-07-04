{...}: {
  flake.modules.nixos.magicplank = {
    lib,
    pkgs,
    ...
  }: {
    services.onepassword-secrets = {
      enable = true;
      secrets = {
        journalSentimentToken = {
          path = "/var/lib/opnix/secrets/journal-sentiment/token";
          reference = "op://Secrets/Journal Sentiment Realtime/token";
          mode = "0640";
        };
        journalSentimentVaultId = {
          path = "/var/lib/opnix/secrets/journal-sentiment/vault-id";
          reference = "op://Secrets/Journal Sentiment Realtime/vault id";
          mode = "0640";
        };
      };
    };

    systemd.services.journal-sentiment-env = {
      description = "Prepare journal sentiment env file";
      after = ["opnix-secrets.service"];
      requires = ["opnix-secrets.service"];
      before = ["journal-sentiment.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "journal-sentiment-env" ''
          install -Dm 0640 /dev/null /var/lib/opnix/secrets/journal-sentiment/env
          {
            printf 'REALTIME_TOKEN=%s\n' "$(cat /var/lib/opnix/secrets/journal-sentiment/token)"
            printf 'REALTIME_VAULT_ID=%s\n' "$(cat /var/lib/opnix/secrets/journal-sentiment/vault-id)"
          } > /var/lib/opnix/secrets/journal-sentiment/env
        '';
      };
    };

    systemd.services.journal-sentiment = {
      description = "Daily journal sentiment analysis";
      after = ["ollama.service" "journal-sentiment-env.service"];
      requires = ["ollama.service" "journal-sentiment-env.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe pkgs.lavender-vault-journal-sentiment;
        EnvironmentFile = "/var/lib/opnix/secrets/journal-sentiment/env";
      };
    };

    systemd.timers.journal-sentiment = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "*-*-* 00:15:00";
        Persistent = true;
      };
    };
  };
}
