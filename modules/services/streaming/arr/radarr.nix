{config, ...}: {
  flake.services.radarr = {
    domains ? [],
    networks ? [],
    container_name ? "radarr",
    restart ? "unless-stopped",
    image ? config.flake.lib.image "linuxserver/radarr",
    port ? 7878,
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
  };
}
