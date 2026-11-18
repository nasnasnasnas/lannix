{config, ...}: {
  flake.services.mollysocket = {
    domains ? [],
    networks ? [],
    container_name ? "mollysocket",
    restart ? "always",
    image ? config.flake.lib.image "ghcr.io/mollyim/mollysocket",
    envSecrets ? {},
    environment ? {},
    env_file ? [],
    volumes ? [],
    dataDir,
  }: {
    inherit domains;
    inherit envSecrets;
    inherit container_name;
    inherit image;
    inherit restart;
    inherit networks;
    command = ["server"];
    caddy_port = 8020;
    environment = {
      MOLLY_HOST="0.0.0.0";
      MOLLY_PORT="8020";
      MOLLY_DB="/data/mollysocket.db";
    } // environment;
    volumes = volumes ++ ["${dataDir}:/data"];
  }
    // (
      if env_file == []
      then {}
      else {inherit env_file;}
    );
}
