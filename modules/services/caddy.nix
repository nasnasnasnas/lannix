{config, ...}: {
  flake.services.caddy = {
    networks ? [],
    image ? config.flake.lib.image "ghcr.io/nealol/caddy-cloudflare-l4",
    caddyfilePath,
    envSecrets ? {},
    env_file ? [],
    dataDir ? "/home/magicbox/data/caddy",
    extraPorts ? [],
  }:
    {
      container_name = "caddy";
      inherit image;
      restart = "always";
      domains = [];
      caddy_port = null;
      command = ["caddy" "run" "--config" "/etc/caddy/Caddyfile" "--adapter" "caddyfile"];
      healthcheck = {
        test = ["CMD" "curl" "-fsS" "http://127.0.0.1:2019/config/"];
        interval = "30s";
        timeout = "5s";
        retries = 3;
        start_period = "10s";
      };
      inherit networks envSecrets;
      ports =
        [
          "80:80"
          "443:443"
          "443:443/udp"
        ]
        ++ extraPorts;
      volumes = [
        "${caddyfilePath}:/etc/caddy/Caddyfile:ro"
        "${dataDir}:/data"
      ];
    }
    // (
      if env_file == []
      then {}
      else {inherit env_file;}
    );
}
