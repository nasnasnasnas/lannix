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
    volumes = volumes ++ ["${dataDir}:/var/cache/ntfy"];
  };
}
