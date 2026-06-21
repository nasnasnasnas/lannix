{inputs, ...}: {
  flake.modules.nixos.magicplank = {pkgs, ...}: {
    services.onepassword-secrets = {
      enable = true;
      secrets = {
        openWebuiOauthClientId = {
          path = "/var/lib/opnix/secrets/open-webui/oauth_client_id";
          reference = "op://Secrets/Open WebUI OAuth/client id";
          mode = "0640";
        };
        openWebuiOauthClientSecret = {
          path = "/var/lib/opnix/secrets/open-webui/oauth_client_secret";
          reference = "op://Secrets/Open WebUI OAuth/client secret";
          mode = "0640";
        };
      };
    };

    systemd.services.open-webui-oauth-env = {
      description = "Prepare open-webui OAuth env file";
      after = ["opnix-secrets.service"];
      requires = ["opnix-secrets.service"];
      before = ["magicplank.service"];
      wantedBy = ["magicplank.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "open-webui-oauth-env" ''
          install -Dm 0640 /dev/null /var/lib/opnix/secrets/open-webui/oauth.env
          {
            printf 'OAUTH_CLIENT_ID=%s\n' "$(cat /var/lib/opnix/secrets/open-webui/oauth_client_id)"
            printf 'OAUTH_CLIENT_SECRET=%s\n' "$(cat /var/lib/opnix/secrets/open-webui/oauth_client_secret)"
          } > /var/lib/opnix/secrets/open-webui/oauth.env
        '';
      };
    };
  };
}
