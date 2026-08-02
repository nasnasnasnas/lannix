{config, ...}: {
  flake.services.grafana = {
    domains ? [],
    networks ? [],
    container_name ? "grafana",
    restart ? "unless-stopped",
    image ? config.flake.lib.image "grafana/grafana",
    port ? 3000,
    environment ? {},
    volumes ? [],
    user ? "1000:100",
    plugins ? [],
    tz ? "America/Indiana/Indianapolis",
    dataDir ? "/var/lib/grafana",
    adminUser ? "admin",
    datasourcesYaml ? ./grafana-datasources.yaml,
    dashboardsYaml ? ./grafana-dashboards.yaml,
    serverHostsDashboard ? ./server-hosts.json,
    minecraftDashboard ? ./minecraft.json,
    env_file ? [],
    envSecrets ? {},
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
      inherit envSecrets;
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
          if domains != []
          then {GF_SERVER_ROOT_URL = builtins.head domains;}
          else {}
        )
        // environment;
      volumes =
        volumes
        ++ [
          "${dataDir}:/var/lib/grafana:rw"
          "${datasourcesYaml}:/etc/grafana/provisioning/datasources/datasources.yaml:ro"
          "${dashboardsYaml}:/etc/grafana/provisioning/dashboards/dashboards.yaml:ro"
          "${serverHostsDashboard}:/etc/grafana/provisioning/dashboards/server-hosts.json:ro"
          "${minecraftDashboard}:/etc/grafana/provisioning/dashboards/minecraft.json:ro"
        ];
      healthcheck = {
        test = ["CMD" "curl" "-fsS" "http://127.0.0.1:3000/api/health"];
        interval = "30s";
        timeout = "5s";
        retries = 3;
        start_period = "60s";
      };
    }
    // (
      if env_file == []
      then {}
      else {inherit env_file;}
    );
}
