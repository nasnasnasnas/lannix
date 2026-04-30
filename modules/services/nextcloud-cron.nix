{...}: {
  flake.services.nextcloud-cron = {
    networks ? [],
    image ? "nextcloud:latest",
    volumes ? [],
    dataDir ? "/home/magicbox/data/nextcloud"
  }: {
    container_name = "nextcloud-cron";
    entrypoint = "/cron.sh";
    postgres = true;
    postgresEnv = {
      host = "POSTGRES_HOST";
      database = "POSTGRES_DB";
      user = "POSTGRES_USER";
      passwordFile = "POSTGRES_PASSWORD_FILE";
      overrideDatabase = "nextcloud";
    };
    environment = {
      APACHE_SERVER_NAME = "next.szpunar.cloud";
    };
    inherit image;
    restart = "unless-stopped";
    inherit networks;
    volumes = volumes ++ [ "${dataDir}:/var/www/html:z" ];
  };
}
