{inputs, ...}: {
  flake.modules.nixos.remotebox = inputs.self.lib.mkHostServices {
    publicIPs = ["45.8.201.111"];
    caddy = {
      envSecrets = {
        CF_API_TOKEN = "op://Secrets/Caddy Cloudflare Token for HTTPS/password";
      };
    };
    projects = {
      helloworld = {
        services = with inputs.self.services; [
          (helloworld {domains = ["https://helloworld.szpunar.cloud"];})
        ];
      };
      pocket-id = {
        services = with inputs.self.services; [
          (pocket-id {domains = ["https://auth.szpunar.cloud"];})
        ];
      };
      picturesplace = {
        services = with inputs.self.services; [
          (picturesplace {
            domains = ["https://pictures.place"];
            dataDir = "/home/magicbox/data/picturesplace";
            envSecrets = {
              BETTER_AUTH_SECRET = "op://Secrets/pictures.place Production Secrets/Better Auth Secret";
              BETTER_AUTH_API_KEY = "op://Secrets/pictures.place Production Secrets/Better Auth API Key";
              POSTMARK_API_KEY = "op://Secrets/pictures.place Production Secrets/Postmark API Key";
              R2_ACCESS_KEY_ID = "op://Secrets/pictures.place Production Secrets/R2 Access Key ID";
              R2_SECRET_ACCESS_KEY = "op://Secrets/pictures.place Production Secrets/R2 Access Key";
              ANTHROPIC_API_KEY = "op://Secrets/pictures.place Production Secrets/Anthropic API Key";
              XWEATHER_CLIENT_ID = "op://Secrets/pictures.place Production Secrets/Xweather Client ID";
              XWEATHER_CLIENT_SECRET = "op://Secrets/pictures.place Production Secrets/Xweather Client Secret";
            };
            environment = {
              QUEUE_DB = "/data/queue.db";
              DATABASE_URL = "file:/data/data.db";
              BETTER_AUTH_URL = "https://pictures.place";
              POSTMARK_FROM_EMAIL = "noreply@pictures.place";
              IDLE_TIMEOUT = "120";
              R2_ENDPOINT = "https://fbabfa5497ca37a8a9182de4c40d5ff9.r2.cloudflarestorage.com";
              R2_PUBLIC_URL = "https://uploads.pictures.place";
              R2_BUCKET_NAME = "pictures-place";
              CF_TRANSFORM_BASE_URL = "https://uploads.pictures.place";
            };
          })
        ];
      };
      realtime = {
        services = with inputs.self.services; [
          (realtime-md {
            domains = ["https://realtime.szpunar.cloud"];
            envSecrets = {
              OIDC_CLIENT_ID = "op://Secrets/Realtime.md Production Secrets/OIDC Client ID";
              OIDC_CLIENT_SECRET = "op://Secrets/Realtime.md Production Secrets/OIDC Client Secret";
              YSWEET_AUTH_KEY = "op://Secrets/Realtime.md Production Secrets/Ysweet Auth Key";
            };
            environment = {
              OIDC_MODE = "oidc";
              OIDC_ISSUER = "https://auth.szpunar.cloud";
              PUBLIC_BASE_URL = "https://realtime.szpunar.cloud";
            };
          })
        ];
      };
      umami = {
        services = with inputs.self.services; [
          (umami {domains = ["https://umami.szpunar.cloud"];})
        ];
      };
      minecraft = {
        services = with inputs.self.services; [
          (minecraft {
            container_name = "wokecraft";
            domains = ["https://wokecraft.szpunar.cloud"];
            caddyPort = 8100;
            dataDir = "/home/magicbox/data/wokecraft";
            pack = "wokecraft";
            loaderVersion = "21.1.247";
            memory = "8G";
            ports = ["127.0.0.1:19565:19565"];
            environment = {
              DIFFICULTY = "normal";
              ENABLE_WHITELIST = "true";
              WHITELIST = "neasgay,vaivoe,limboLegion,fujisaki_chihiro,beatmania_iidx,silicasandwhich,ceramiccryptid,_MACOSX";
              OPS = "neasgay,vaivoe";
              ENABLE_QUERY = "true";
              MOTD = "\\u00A7b\\u00A7lWo\\u00A7d\\u00A7lke\\u00A7f\\u00A7lcr\\u00A7d\\u00A7laf\\u00A7b\\u00A7lt!";
              REMOVE_OLD_MODS = "true";
              ENFORCE_SECURE_PROFILE = "false";
            };
          })
          (minecraft-monitor {
            container_name = "wokecraft-monitor";
            serverHost = "wokecraft";
          })
        ];
      };
    };
  };
}
