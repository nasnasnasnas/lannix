{...}: {
  flake.services.postgres = {
    networks ? [],
    image ? "postgres:latest",
    dataDir ? "/home/magicbox/data/postgres",
  }: {
    container_name = "postgres";
    inherit image networks;
    restart = "always";
    volumes = [
      "${dataDir}:/var/lib/postgresql"
    ];
  };
}
