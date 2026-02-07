{...}: {
  flake.services.grafana = {
    domains ? [],
    networks ? [],
    container_name ? "grafana",
    restart ? "unless-stopped",
    image ? "grafana/grafana:latest",
    port ? 3000,
    environment ? {},
    volumes ? [],
    user ? "1000:100",
    plugins ? [],
    tz ? "America/Indiana/Indianapolis",
    dataDir ? "/var/lib/grafana"
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
      GF_SECURITY_ADMIN_USER = "admin";
      GF_SECURITY_ADMIN_PASSWORD = "admin"; # Changed after first run
      GF_PLUGINS_PREINSTALL = builtins.concatStringsSep "," plugins;
    }
    // (if domains != [] then { GF_SERVER_ROOT_URL = builtins.head domains; } else {})
    // environment;
    volumes = volumes ++ [ "${dataDir}:/var/lib/grafana:rw" ];
  };
}
