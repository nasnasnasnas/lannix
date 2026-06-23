{inputs, ...}: {
  flake.modules.nixos.magicplank = inputs.self.lib.mkHostServices {
    publicIPs = ["107.219.61.126" "100.100.165.5"];
    caddy = {
      envSecrets = {
        CF_API_TOKEN = "op://Secrets/Caddy Cloudflare Token for HTTPS/password";
      };
    };
    services = with inputs.self.services; [
      (nextcloud {domains = ["https://next.szpunar.cloud"];})
      (nextcloud-cron {})
      (forgejo {domains = ["https://git.szpunar.cloud"];})
      (atticd {domains = ["https://attic.szpunar.cloud"];})
      (gomuks {
        domains = ["https://leah.gomuks.szpunar.cloud"];
        dataDir = "/home/magicbox/data/gomuks-leah";
      })
      (open-webui {
        domains = ["https://ai.szpunar.cloud"];
        envSecrets = {
          OAUTH_CLIENT_ID = "op://Secrets/Open WebUI OAuth/client id";
          OAUTH_CLIENT_SECRET = "op://Secrets/Open WebUI OAuth/client secret";
        };
        oidc = {
          providerUrl = "https://auth.szpunar.cloud/.well-known/openid-configuration";
          redirectUri = "https://ai.szpunar.cloud/oauth/oidc/callback";
          providerName = "Pocket ID";
        };
      })
    ];
  };
}
