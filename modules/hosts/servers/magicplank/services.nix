{inputs, ...}: {
  flake.modules.nixos.magicplank = inputs.self.lib.mkHostServices {
    publicIPs = ["107.219.61.126"];
    # Internal app networks for the migrated Pi stacks. caddy joins synapse-net so the
    # matrix-rtc caddyRaw block can reach the lk-jwt auth-service backend (which has no domain).
    networks = ["synapse-net" "sharkey-net"];
    caddy = {
      extraNetworks = ["synapse-net"];
      # Expose TURNS and terminate its TLS at layer4, proxying plain to livekit:5349
      # (livekit.yaml has external_tls: true). The cert is provisioned by the cert-primer
      # site in the livekit caddyRaw block.
      extraPorts = ["5349:5349"];
      globalConfig = ''
        {
            layer4 {
                :5349 {
                    @turns tls sni turn.matrix-rtc.szp.lol
                    route @turns {
                        tls
                        proxy livekit:5349
                    }
                }
            }
        }
      '';
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

      # Synapse / Matrix

      (synapse {
        # matrix.szp.lol serves client+federation; szp.lol serves the well-known delegation.
        domains = ["https://matrix.szp.lol" "https://szp.lol"];
        networks = ["synapse-net"];
        dataDir = "/home/magicbox/data/synapse";
        secretsFragment = "op://Secrets/Synapse Config Secrets/notesPlain";
        signingKeySecret = "op://Secrets/Synapse Signing Key/notesPlain";
        appserviceRegistrations = {
          "/data/heisenbridge.yaml" = "op://Secrets/Heisenbridge Registration/notesPlain";
          "/data/mautrix-telegram.yaml" = "op://Secrets/Mautrix Telegram Registration/notesPlain";
          "/data/mautrix-signal.yaml" = "op://Secrets/Mautrix Signal Registration/notesPlain";
          "/data/mautrix-discord.yaml" = "op://Secrets/Mautrix Discord Registration/notesPlain";
        };
      })

      (dedicated-postgres {
        container_name = "synapse-db";
        networks = ["synapse-net"];
        dataDir = "/home/magicbox/data/synapse-db";
        db = "synapse";
        user = "synapse";
        initdbArgs = "--encoding=UTF-8 --lc-collate=C --lc-ctype=C";
        envSecrets = {
          POSTGRES_PASSWORD = "op://Secrets/Synapse DB/password";
        };
      })

      (heisenbridge {
        networks = ["synapse-net"];
        dataDir = "/home/magicbox/data/heisenbridge";
        configSecret = "op://Secrets/Heisenbridge Registration/notesPlain";
      })
      (heisenbridge {
        media = true;
        domains = ["https://heisenbridge.szp.lol"];
        networks = ["synapse-net"];
        dataDir = "/home/magicbox/data/heisenbridge";
        configSecret = "op://Secrets/Heisenbridge Registration/notesPlain";
      })

      (mautrix {
        bridge = "telegram";
        networks = ["synapse-net"];
        dataDir = "/home/magicbox/data/mautrix-telegram";
      })
      (mautrix {
        bridge = "signal";
        networks = ["synapse-net"];
        dataDir = "/home/magicbox/data/mautrix-signal";
      })
      (mautrix {
        bridge = "discord";
        domains = ["https://mautrix-discord.szp.lol"];
        webPort = 29334;
        networks = ["synapse-net"];
        dataDir = "/home/magicbox/data/mautrix-discord";
      })

      # Matrix RTC

      (lk-jwt {
        networks = ["synapse-net"];
        livekitUrl = "https://matrix-rtc.szp.lol/livekit/sfu";
        fullAccessHomeservers = "szp.lol";
        envSecrets = {
          LIVEKIT_KEY = "op://Secrets/LiveKit/key";
          LIVEKIT_SECRET = "op://Secrets/LiveKit/secret";
        };
      })
      (livekit {
        domains = ["https://matrix-rtc.szp.lol" "https://turn.matrix-rtc.szp.lol"];
        networks = ["synapse-net"];
        configSecret = "op://Secrets/LiveKit Config/notesPlain";
      })

      # Sharkey

      (sharkey {
        domains = ["https://social.szp.lol"];
        networks = ["sharkey-net"];
        dataDir = "/home/magicbox/data/sharkey/files";
        configSecret = "op://Secrets/Sharkey Config/notesPlain";
      })
      (dedicated-postgres {
        container_name = "sharkey-db";
        image = "groonga/pgroonga:4.0.1-alpine-17";
        networks = ["sharkey-net"];
        dataDir = "/home/magicbox/data/sharkey-db";
        db = "misskey";
        user = "example-misskey-user";
        envSecrets = {
          POSTGRES_PASSWORD = "op://Secrets/Sharkey DB/password";
        };
      })
      (redis {
        container_name = "sharkey-redis";
        networks = ["sharkey-net"];
        dataDir = "/home/magicbox/data/sharkey-redis";
      })
    ];
  };
}
