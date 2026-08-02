{config, ...}: {
  flake.services.picturesplace = {
    domains ? [],
    networks ? [],
    image ? config.flake.lib.image "git.szpunar.cloud/leah/pictures.place",
    volumes ? [],
    envSecrets ? {},
    environment ? {},
    env_file ? [],
    dataDir,
  }:
    {
      inherit domains;
      container_name = "picturesplace";
      inherit image;
      inherit envSecrets;
      restart = "unless-stopped";
      caddy_port = 3000;
      healthcheck = {
        test = ["CMD" "bun" "-e" "fetch('http://127.0.0.1:3000/').then(r=>process.exit(r.status<500?0:1)).catch(()=>process.exit(1))"];
        interval = "30s";
        timeout = "5s";
        retries = 3;
        start_period = "60s";
      };
      inherit networks;
      volumes = volumes ++ ["${dataDir}:/data"];
      environment =
        {
          QUEUE_DB = "/data/queue.db";
          DATABASE_URL = "file:/data/data.db";
          IDLE_TIMEOUT = "120";
        }
        // environment;
    }
    // (
      if env_file == []
      then {}
      else {inherit env_file;}
    );
}
