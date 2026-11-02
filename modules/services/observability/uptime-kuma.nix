{config, ...}: {
  flake.services.uptime-kuma = {
    domains ? [],
    networks ? [],
    container_name ? "uptime-kuma",
    restart ? "unless-stopped",
    image ? config.flake.lib.image "louislam/uptime-kuma",
    volumes ? [],
    dataDir,
  }: {
    inherit domains;
    inherit container_name;
    inherit image;
    inherit restart;
    inherit networks;
    caddy_port = 3001;
    volumes = volumes ++ ["${dataDir}:/app/data"];
  };
}
