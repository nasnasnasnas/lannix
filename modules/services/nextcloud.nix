{...}: {
  flake.services.nextcloud = {
    domains ? [],
    networks ? [],
    image ? "nextcloud:latest",
    volumes ? [],
    dataDir ? "/home/magicbox/data/nextcloud"
  }: {
    inherit domains;
    container_name = "nextcloud";
    postgres = true;
    postgresEnv = {
      host = "POSTGRES_HOST";
      database = "POSTGRES_DB";
      user = "POSTGRES_USER";
      passwordFile = "POSTGRES_PASSWORD_FILE";
    };
    inherit image;
    restart = "unless-stopped";
    caddy_port = 80;
    inherit networks;
    volumes = volumes ++ [ "${dataDir}:/var/www/html" ];
  };
}
