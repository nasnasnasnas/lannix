{...}: {
  flake.services.nzbdav = {
    domains ? [],
    networks ? [],
    container_name ? "nzbdav",
    restart ? "unless-stopped",
    image ? "nzbdav/nzbdav:latest",
    port ? 3000,
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
    healthcheck = {
      test = ["CMD-SHELL" "curl" "-f" "http://localhost:3000/health" "||" "exit" "1"];
      interval = "1m";
      retries = 3;
      start_period = "5s";
      timeout = "5s";
    };
  };

  flake.services.nzbdav-rclone = {
    domains ? [],
    networks ? [],
    container_name ? "nzbdav-rclone",
    restart ? "unless-stopped",
    image ? "rclone/rclone:latest",
    port,
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
    depends_on ? [
      "nzbdav"
    ],
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
