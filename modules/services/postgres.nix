{...}: {
  flake.services.postgres = {
    networks ? [],
    image ? "postgres:latest",
    dataDir ? "/home/magicbox/data/postgres",
    restart ? "always",
    user ? null,
    environment ? {},
    ports ? [],
    volumes ? [],
    configDir ? null,
  }:
    {
      container_name = "postgres";
      inherit image networks;
      inherit restart;
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
    );
}
