{config, ...}: {
  flake.services.ntfy = {
    domains ? [],
    networks ? [],
    image ? config.flake.lib.image "docker.io/binwiederhier/ntfy",
    volumes ? [],
    dataDir ? "/home/magicbox/data/ntfy",
  }: {
    inherit domains;
    container_name = "ntfy";
    inherit image;
    restart = "unless-stopped";
    caddy_port = 80;
    inherit networks;
    environment = {
      APP_URL = builtins.head domains;
      ENCRYPTION_KEY_FILE = "/app/data/encryption-key";
      MAXMIND_LICENSE_KEY_FILE = "/app/data/maxmind-license";
      TRUST_PROXY = "true";
    };
    volumes = volumes ++ ["${dataDir}:/var/cache/ntfy"];
  };
}
