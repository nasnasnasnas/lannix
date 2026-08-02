{config, ...}: {
  flake.services.nzbdav = {
    domains ? [],
    networks ? [],
    container_name ? "nzbdav",
    restart ? "unless-stopped",
    image ? config.flake.lib.image "ghcr.io/nealol/nzbdav",
    port ? 3000,
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
      test = ["CMD" "curl" "-fsS" "http://127.0.0.1:3000/health"];
      interval = "30s";
      timeout = "5s";
      retries = 3;
      start_period = "30s";
    };
  };

  flake.services.nzbdav-rclone = {
    domains ? [],
    networks ? [],
    container_name ? "nzbdav-rclone",
    restart ? "unless-stopped",
    image ? config.flake.lib.image "rclone/rclone",
    port ? null,
    user ? "1000:100",
    command ? [
      "mount"
      "nzbdav:"
      "/mnt/nzbdav"
      "--uid=1000"
      "--gid=100"
      "--allow-other"
      "--links"
      "--use-cookies"
      "--allow-non-empty"
      "--vfs-cache-mode=full"
      "--vfs-cache-max-size=100G"
      "--vfs-cache-max-age=24h"
      "--buffer-size=0M"
      "--vfs-read-ahead=512M"
      "--dir-cache-time=20s"
    ],
    environment ? {},
    volumes ? [],
    depends_on ? {
      nzbdav = {
        condition = "service_healthy";
      };
    },
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
    environment =
      {
        PUID = uid;
        PGID = gid;
        TZ = "America/Indiana/Indianapolis";
      }
      // environment;
    inherit volumes;
    healthcheck = {
      test = ["CMD" "rclone" "lsf" "/mnt/nzbdav" "--max-depth" "1"];
      interval = "30s";
      timeout = "10s";
      retries = 3;
      start_period = "60s";
    };
    inherit depends_on;
    capabilities = {
      SYS_ADMIN = true;
    };
    devices = ["/dev/fuse:/dev/fuse:rwm"];
    inherit command;
    out = {
      security_opt = ["apparmor=unconfined"];
    };
  };
}
