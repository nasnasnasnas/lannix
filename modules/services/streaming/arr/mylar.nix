{config, ...}: {
  flake.services.mylar = {
    domains ? [],
    networks ? [],
    container_name ? "mylar",
    restart ? "unless-stopped",
    image ? config.flake.lib.image "linuxserver/mylar",
    port ? 8090,
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
      test = ["CMD" "curl" "-fsS" "http://127.0.0.1:8090/"];
      interval = "30s";
      timeout = "5s";
      retries = 3;
      start_period = "60s";
    };
  };
}
