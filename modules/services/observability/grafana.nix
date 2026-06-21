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
    dataDir ? "/var/lib/grafana",
    adminUser ? "admin",
    adminPassword ? "adminpassword",
    env_file ? [],
  }: let
    parts = builtins.match "([^:]+):([^:]+)" user;
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
      environment =
        {
          PUID = uid;
          PGID = gid;
          TZ = tz;
          GF_SECURITY_ADMIN_USER = adminUser;
          GF_PLUGINS_PREINSTALL = builtins.concatStringsSep "," plugins;
        }
        // (
          if adminPassword != null
          then {GF_SECURITY_ADMIN_PASSWORD = adminPassword;}
          else {}
        )
        // (
          if domains != []
          then {GF_SERVER_ROOT_URL = builtins.head domains;}
          else {}
        )
        // environment;
      volumes = volumes ++ ["${dataDir}:/var/lib/grafana:rw"];
    }
    // (
      if env_file == []
      then {}
      else {inherit env_file;}
    );
}
