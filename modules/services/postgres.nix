{...}: {
  flake.services.postgres = {
    networks ? [],
    image ? "postgres:latest",
    dataDir ? "/home/magicbox/data/postgres",
  }: {
    container_name = "postgres";
    inherit image networks;
    restart = "always";
    environment = {
      APACHE_SERVER_NAME = "next.szpunar.cloud";
    };
    volumes = [
      "${dataDir}:/var/lib/postgresql"
    ];
  };
}
