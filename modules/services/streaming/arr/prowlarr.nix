{config, ...}: {
  flake.services.prowlarr = {
    domains ? [],
    networks ? [],
    container_name ? "prowlarr",
    restart ? "unless-stopped",
    image ? config.flake.lib.image "linuxserver/prowlarr",
    port ? 9696,
    user ? "1000:100",
    environment ? {},
    volumes ? [],
    configDir,
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
        TZ = "America/Indiana/Indianapolis";
      }
      // environment;
    volumes = volumes ++ ["${configDir}:/config"];
    healthcheck = {
      test = ["CMD" "curl" "-fsS" "http://127.0.0.1:9696/ping"];
      interval = "30s";
      timeout = "5s";
      retries = 3;
      start_period = "60s";
    };
  };
}
