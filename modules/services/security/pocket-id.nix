{config, ...}: {
  flake.services.pocket-id = {
    domains ? [],
    networks ? [],
    image ? config.flake.lib.image "ghcr.io/pocket-id/pocket-id",
    volumes ? [],
    dataDir ? "/home/magicbox/data/pocket-id",
  }: {
    inherit domains;
    container_name = "pocket-id";
    inherit image;
    restart = "unless-stopped";
    caddy_port = 1411;
    inherit networks;
    environment = {
      APP_URL = builtins.head domains;
      ENCRYPTION_KEY_FILE = "/app/data/encryption-key";
      MAXMIND_LICENSE_KEY_FILE = "/app/data/maxmind-license";
      TRUST_PROXY = "true";
    };
    volumes = volumes ++ ["${dataDir}:/app/data"];
  };
}
