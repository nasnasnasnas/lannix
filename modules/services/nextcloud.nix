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
    inherit image;
    restart = "unless-stopped";
    caddy_port = 80;
    inherit networks;
    volumes = volumes ++ [ "${dataDir}:/var/www/html" ];
  };
}
