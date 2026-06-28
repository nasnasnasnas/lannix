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
      volumes = volumes ++ ["${dataDir}:/data"];
    }
    // (
      if env_file == []
      then {}
      else {inherit env_file;}
    );
}
