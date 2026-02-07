{...}: {
  flake.services.pyroscope = {
    domains ? [],
    networks ? [],
    container_name ? "pyroscope",
    restart ? "unless-stopped",
    image ? "grafana/pyroscope:latest",
    port ? 4040,
    environment ? {},
    volumes ? [],
    user ? "1000:100",
    plugins ? [],
    tz ? "America/Indiana/Indianapolis",
    command ? [],
    dataDir ? "/var/lib/pyroscope"
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
    volumes = volumes ++ [ "${dataDir}:/var/lib/pyroscope:rw" ];
    inherit command;
  };
}
