{config, ...}: {
  flake.services.victoriametrics = {
    domains ? [],
    networks ? [],
    container_name ? "victoriametrics",
    restart ? "unless-stopped",
    image ? config.flake.lib.image "victoriametrics/victoria-metrics",
    port ? 8428,
    environment ? {},
    volumes ? [],
    user ? "1000:100",
    plugins ? [],
    tz ? "America/Indiana/Indianapolis",
    command ? [],
    dataDir,
  }: let
    parts = builtins.match "([^:]+):([^:]+)" user;
    uid = builtins.elemAt parts 0;
    gid = builtins.elemAt parts 1;
  in {
    inherit domains;
    inherit container_name;
    inherit image;
    inherit restart;
    inherit networks;
    caddy_port = port;
    environment =
      {
        PUID = uid;
        PGID = gid;
        TZ = tz;
      }
      // environment;
    volumes = volumes ++ ["${dataDir}:/victoria-metrics-data:rw"];
    command =
      [
        "--storageDataPath=/victoria-metrics-data"
        "--httpListenAddr=:${builtins.toString port}"
        "--selfScrapeInterval=5s"
      ]
      ++ command;
  };
}
