{inputs, ...}: {
  flake.modules.nixos.remotebox = inputs.self.lib.mkHostServices {
    publicIPs = ["45.8.201.111"];
    caddy = {
      envSecrets = {
        CF_API_TOKEN = "op://Secrets/Caddy Cloudflare Token for HTTPS/password";
      };
    };
    services = with inputs.self.services; [
      (helloworld {domains = ["https://helloworld.szpunar.cloud"];})
      (pocket-id {domains = ["https://auth.szpunar.cloud"];})
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
      (pulse {
        domains = ["https://pulse.szp.lol"];
        envSecrets = {
          # TODO: replace with unique api key
          ANTHROPIC_API_KEY = "op://Secrets/pictures.place Production Secrets/Anthropic API Key";
          BETTER_AUTH_SECRET = "op://Secrets/Pulse Production Secrets/Better Auth Secret";
          TELEGRAF_SALT = "op://Secrets/Pulse Production Secrets/Telegraf Salt";
        };
        environment = let
          url = "https://pulse.szp.lol";
        in {
          BETTER_AUTH_URL = url;
          PUBLIC_APP_URL = url;
          POSTGRES_USER = "postgres";
          POSTGRES_PASSWORD = "password";
          POSTGRES_BIND_ADDRESS = "172.17.0.1";
          POSTGRES_PORT = "5432";
          POSTGRES_BASE_URL = "postgres://postgres:password@172.17.0.1:5432";
          AUTH_DATABASE_URL = "postgres://postgres:password@172.17.0.1:5432/auth?options=-c%20search_path%3Dauth";
          AUTH_SCHEMA = "auth";
          TIMESCALE_DATABASE = "timescale";
          DEMO_MODE_TABLE = "metrics_929be68962f58b60e0853809cfe78c131f30ea33";
          DEMO_MODE_USER = "68223fa4-172e-4349-8128-8a22a01d77d3";
        };
      })
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
}
