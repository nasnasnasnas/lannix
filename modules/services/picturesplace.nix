{...}: {
  flake.services.picturesplace = {
    domains ? [],
    networks ? [],
    image ? "git.szpunar.cloud/leah/pictures.place:3e77c5e7a23960c31278efba6f4e1090329d4bc2",
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
