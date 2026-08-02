{config, ...}: {
  flake.services.jellyfin = {
    domains ? [],
    networks ? [],
    container_name ? "jellyfin",
    restart ? "always",
    image ? config.flake.lib.image "linuxserver/jellyfin",
    port ? 8096,
    environment ? {},
    volumes ? [],
    user ? "1000:100",
    nvidia ? false,
    depends_on ? [],
    tz ? "America/Indiana/Indianapolis",
    command ? [],
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
        }
        // (
          if nvidia == true
          then {NVIDIA_VISIBLE_DEVICES = "all";}
          else {}
        )
        // (
          if domains != []
          then {JELLYFIN_PublishedServerUrl = builtins.head domains;}
          else {}
        )
        // environment;
      inherit volumes;
      inherit command;
      inherit depends_on;
      healthcheck = {
        test = ["CMD" "curl" "-fsS" "http://127.0.0.1:8096/health"];
        interval = "30s";
        timeout = "10s";
        retries = 5;
        start_period = "120s";
      };
    }
    // (
      if nvidia == true
      then {
        out = {
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
        };
      }
      else {}
    );
}
