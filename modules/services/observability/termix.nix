{...}: {
  flake.services.termix = {
    domains ? [],
    networks ? [],
    container_name ? "termix",
    restart ? "unless-stopped",
    image ? "ghcr.io/lukegus/termix:latest",
    port ? 8080,
    environment ? {},
    volumes ? [],
    dataDir
  }: {
    inherit domains;
    inherit container_name;
    inherit image;
    inherit restart;
    inherit networks;
    caddy_port = port;
    environment = {
      PORT = builtins.toString port;
    } // environment;
    volumes = volumes ++ [ "${dataDir}:/app/data" ];
  };
}
