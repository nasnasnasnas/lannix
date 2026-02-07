{...}: {
  flake.services.victorialogs = {
    domains ? [],
    networks ? [],
    container_name ? "victorialogs",
    restart ? "unless-stopped",
    image ? "victoriametrics/victorialogs:latest",
    port ? 9000,
    environment ? {},
    volumes ? [],
    user ? "1000:100",
    plugins ? [],
    tz ? "America/Indiana/Indianapolis",
    command ? [],
    dataDir
  }: let
    parts = builtins.split ":" user;
    uid = builtins.elemAt parts 0;
    gid = builtins.elemAt parts 1;
  in 
  {
    inherit domains;
    inherit container_name;
    inherit image;
    inherit restart;
    inherit networks;
    caddy_port = port;
    environment = {
      PUID = uid;
      PGID = gid;
      TZ = tz;
    } // environment;
    volumes = volumes ++ [ "${dataDir}:/victoria-logs-data:rw" ];
    command = [
      "--storageDataPath=/victoria-logs-data"
      "--httpListenAddr=:${builtins.toString port}"
    ] ++ command;
  };
}
