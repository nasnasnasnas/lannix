{...}: {
  flake.services.jellyfin = {
    domains ? [],
    networks ? [],
    container_name ? "jellyfin",
    restart ? "unless-stopped",
    image ? "linuxserver/jellyfin:latest",
    port ? 8096,
    environment ? {},
    volumes ? [],
    user ? "1000:100",
    nvidia ? false,
    depends_on ? [],
    tz ? "America/Indiana/Indianapolis",
    command ? [],
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
    }
    // (if nvidia == true then { NVIDIA_VISIBLE_DEVICES = "all"; } else {})
    // (if domains != [] then { JELLYFIN_PublishedServerUrl = builtins.head domains; } else {})
    // environment;
    inherit volumes;
    inherit command;
    inherit depends_on;
  }
  // (if nvidia == true then { out = {
    deploy = {
      resources = {
        reservations = {
          devices = [
            {
              driver = "cdi";
              device_ids = ["nvidia.com/gpu=all"];
              capabilities = ["gpu"];
            }
          ];
        };
      };
    };
  }; } else {});
}
