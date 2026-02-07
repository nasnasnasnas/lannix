{...}: {
  flake.services.prowlarr = {
    domains ? [],
    networks ? [],
    container_name ? "prowlarr",
    restart ? "unless-stopped",
    image ? "linuxserver/prowlarr:latest",
    port ? 9696,
    user ? "1000:100",
    environment ? {},
    volumes ? [],
    configDir,
  }: let
    parts = builtins.split ":" user;
    uid = builtins.elemAt parts 0;
    gid = builtins.elemAt parts 1;
  in {
    inherit domains;
    inherit container_name;
    inherit image;
    inherit restart;
    inherit networks;
    caddy_port = port;
    environment = {
      PUID = uid;
      PGID = gid;
      TZ = "America/Indiana/Indianapolis";
    } // environment;
    volumes = volumes ++ [ "${configDir}:/config" ];
  };
}
