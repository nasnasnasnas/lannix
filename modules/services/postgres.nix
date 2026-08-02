{config, ...}: {
  flake.services.postgres = {
    networks ? [],
    image ? config.flake.lib.image "postgres:latest",
    dataDir ? "/home/magicbox/data/postgres",
    restart ? "always",
    user ? null,
    environment ? {},
    ports ? [],
    volumes ? [],
    configDir ? null,
    fileSecrets ? {},
  }:
    {
      container_name = "postgres";
      inherit image networks;
      inherit restart;
      healthcheck = {
        test = ["CMD" "pg_isready" "-h" "127.0.0.1"];
        interval = "10s";
        timeout = "5s";
        retries = 5;
        start_period = "30s";
      };
      volumes =
        [
          "${dataDir}:/var/lib/postgresql"
        ]
        ++ volumes
        ++ (
          if configDir == null
          then []
          else ["${configDir}:/etc/postgresql:rw"]
        );
    }
    // (
      if user == null
      then {}
      else {inherit user;}
    )
    // (
      if environment == {}
      then {}
      else {inherit environment;}
    )
    // (
      if ports == []
      then {}
      else {inherit ports;}
    )
    // (
      if fileSecrets == {}
      then {}
      else {inherit fileSecrets;}
    );
}
