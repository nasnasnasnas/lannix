{ ... }: {
  flake.services.jellyfin = {
    domains,
    configDir ? "/home/magicbox/config/jellyfin",
    cacheDir ? "/home/magicbox/data/jellyfin",
    mediaDir ? "/home/magicbox/media",
    manualMediaDir ? "/home/magicbox/manual-media",
    network ? "magicbox-network",
  }: {
    container_name = "jellyfin";
    image = "linuxserver/jellyfin:latest";
    restart = "always";
    environment = {
      PUID = "1000";
      PGID = "100";
      TZ = "America/Indiana/Indianapolis";
      JELLYFIN_PublishedServerUrl = "https://${builtins.head domains}";
      NVIDIA_VISIBLE_DEVICES = "all";
    };
    caddy_port = 8096;
    inherit domains;
    networks = [
      network
    ];
    depends_on = [
      "zurg"
      "rclone"
    ];
    volumes = [
      "${configDir}:/config"
      "${cacheDir}:/cache"
      "${mediaDir}:/data"
      "${manualMediaDir}:/data-ro"
      "/mnt/zurg:/media:rshared"
      "/mnt/nzbdav:/mnt/nzbdav:rshared"
    ];
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
  };
}
