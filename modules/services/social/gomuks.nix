{...}: {
  flake.services.gomuks = {
    domains ? [],
    networks ? [],
    container_name ? "gomuks",
    restart ? "unless-stopped",
    image ? "dock.mau.dev/gomuks/gomuks:latest",
    port ? 29325,
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
    inherit environment;
    volumes = volumes ++ [ "${dataDir}:/app/data" ];
  };
}
