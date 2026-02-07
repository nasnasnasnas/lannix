{...}: {
  flake.services.zurg = {
    domains ? [],
    networks ? [],
    container_name ? "zurg",
    restart ? "unless-stopped",
    image ? "ghcr.io/debridmediamanager/zurg-testing:latest",
    port,
    user ? "1000:100",
    environment ? {},
    volumes ? [],
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
    environment = {
      PUID = uid;
      PGID = gid;
      TZ = "America/Indiana/Indianapolis";
    } // environment;
    inherit volumes;
  }
  // (if port != null then { caddy_port = port; } else {});

  flake.services.zurg-rclone = {
    domains ? [],
    networks ? [],
    container_name ? "rclone", # just plain "rclone" for legacy reasons
    restart ? "unless-stopped",
    image ? "rclone/rclone:latest",
    port,
    user ? "1000:100",
    command ? [
                "mount"
                "zurg:"
                "/data"
                "--allow-other"
                "--allow-non-empty"
                "--dir-cache-time"
                "10s"
                "--poll-interval"
                "15s"
                "--umask"
                "000"
                "--vfs-cache-mode"
                "full"
              ],
    environment ? {},
    volumes ? [],
    depends_on ? [ "zurg" ],
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
    environment = {
      PUID = uid;
      PGID = gid;
      TZ = "America/Indiana/Indianapolis";
    } // environment;
    inherit volumes;
    inherit depends_on;
    capabilities = [ "SYS_ADMIN" ];
    devices = [ "/dev/fuse:/dev/fuse:rwm" ];
    inherit command;
    out = {
      security_opt = [ "apparmor=unconfined" ];
    };
  };
}
