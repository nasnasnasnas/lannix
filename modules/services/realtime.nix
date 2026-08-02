{config, ...}: {
  flake.services.realtime-md = {
    domains ? [],
    networks ? [],
    image ? config.flake.lib.image "ghcr.io/nealol/realtime-server",
    volumes ? [],
    dataDir ? "/home/magicbox/data/realtime",
    envSecrets ? {},
    environment ? {},
    env_file ? [],
  }:
    {
      inherit domains;
      inherit envSecrets;
      container_name = "realtime";
      environment =
        {
        }
        // environment;
      inherit image;
      restart = "unless-stopped";
      inherit networks;
      caddy_port = 8081;
      healthcheck = {
        test = ["CMD" "node" "-e" "fetch('http://127.0.0.1:8081/').then(r=>process.exit(r.status<500?0:1)).catch(()=>process.exit(1))"];
        interval = "30s";
        timeout = "5s";
        retries = 3;
        start_period = "60s";
      };
      volumes = volumes ++ ["${dataDir}:/data"];
      out.ulimits.nofile = {
        soft = 524288;
        hard = 524288;
      };
    }
    // (
      if env_file == []
      then {}
      else {inherit env_file;}
    );
}
