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
