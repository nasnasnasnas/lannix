{inputs, ...}: {
  flake.modules.nixos.magicplank = inputs.self.lib.mkHostServices {
    publicIPs = ["107.219.61.126" "100.100.165.5"];
    services = with inputs.self.services; [
      (nextcloud {domains = ["https://next.szpunar.cloud"];})
      (nextcloud-cron {})
      (forgejo {domains = ["https://git.szpunar.cloud"];})
      (gomuks {domains = ["https://leah.gomuks.szpunar.cloud"]; dataDir = "/home/magicbox/data/gomuks-leah";})
      (open-webui {
        domains = ["https://ai.szpunar.cloud"];
        oauthEnvFile = "/var/lib/opnix/secrets/open-webui/oauth.env";
        oidc = {
          providerUrl = "https://auth.szpunar.cloud/.well-known/openid-configuration";
          redirectUri = "https://ai.szpunar.cloud/oauth/oidc/callback";
          providerName = "Pocket ID";
        };
      })
    ];
  };
}
