{inputs, ...}: {
  flake.modules.nixos.magicbox = inputs.self.lib.mkHostServices {
    publicIPs = ["10.177.177.117"];
    caddy = {
      envSecrets = {
        CF_API_TOKEN = "op://Secrets/Caddy Cloudflare Token for HTTPS/password";
      };
    };
    externalNetworks = ["magicbox-network"];
    projects = with inputs.self.services; {
      media = {
        networks = ["zurg"];
        services = [
          (zurg {
            networks = ["zurg"];
            volumes = [
              "/home/magicbox/config/zurg-testing/config.yml:/app/config.yml"
              "/home/magicbox/data/zurg-testing:/app/data"
            ];
          })

          (zurg-rclone {
            networks = ["zurg"];
            volumes = [
              "/mnt/zurg:/data:rshared"
              "/home/magicbox/config/zurg-testing/rclone.conf:/config/rclone/rclone.conf"
            ];
          })

          (nzbdav {
            domains = ["https://nzbdav.szpunar.cloud" "https://nzbdav.nea.rip"];
            networks = ["magicbox-network"];
            configDir = "/home/magicbox/config/nzbdav";
            volumes = [
              "/mnt/nzbdav:/mnt/nzbdav:rshared"
              "/mnt/extra/media:/data"
            ];
          })

          (nzbdav-rclone {
            networks = ["magicbox-network"];
            volumes = [
              "/mnt/nzbdav:/mnt/nzbdav:rshared"
              "/home/magicbox/config/rclone-nzbdav/rclone.conf:/config/rclone/rclone.conf"
            ];
          })

          (jellyfin {
            domains = ["https://stream.szpunar.cloud" "https://stream.nea.rip" "https://jf.nea.rip"];
            networks = ["magicbox-network"];
            nvidia = true;
            depends_on = {
              zurg = { condition = "service_healthy"; };
              rclone = { condition = "service_healthy"; };
            };
            volumes = [
              "/home/magicbox/config/jellyfin:/config"
              "/home/magicbox/data/jellyfin:/cache"
              "/mnt/extra/media:/data"
              "/home/magicbox/manual-media:/data-ro"
              "/mnt/zurg:/media:rshared"
              "/mnt/nzbdav:/mnt/nzbdav:rshared"
            ];
          })
        ];
      };
      termix = {
        services = [
          (termix {
            domains = ["https://termix.szpunar.cloud" "https://termix.nea.rip"];
            networks = ["magicbox-network"];
            dataDir = "/home/magicbox/data/termix";
          })
        ];
      };
      prowlarr = {
        services = [
          (prowlarr {
            domains = ["https://prowlarr.szpunar.cloud" "https://prowlarr.nea.rip"];
            networks = ["magicbox-network"];
            configDir = "/home/magicbox/config/prowlarr";
          })
        ];
      };
      sonarr = {
        services = [
          (sonarr {
            domains = ["https://sonarr.szpunar.cloud" "https://sonarr.nea.rip"];
            networks = ["magicbox-network"];
            configDir = "/home/magicbox/config/sonarr";
            volumes = [
              "/mnt/extra/media:/data"
              "/mnt/nzbdav:/mnt/nzbdav:rshared"
            ];
          })
        ];
      };
      radarr = {
        services = [
          (radarr {
            domains = ["https://radarr.szpunar.cloud" "https://radarr.nea.rip"];
            networks = ["magicbox-network"];
            configDir = "/home/magicbox/config/radarr";
            volumes = [
              "/mnt/extra/media:/data"
              "/mnt/nzbdav:/mnt/nzbdav:rshared"
            ];
          })
        ];
      };
      lidarr = {
        services = [
          (lidarr {
            domains = ["https://lidarr.szpunar.cloud" "https://lidarr.nea.rip"];
            networks = ["magicbox-network"];
            configDir = "/home/magicbox/config/lidarr";
            volumes = [
              "/mnt/extra/media:/data"
              "/mnt/nzbdav:/mnt/nzbdav:rshared"
            ];
          })
        ];
      };
      mylar = {
        services = [
          (mylar {
            domains = ["https://mylar.szpunar.cloud" "https://mylar.nea.rip"];
            networks = ["magicbox-network"];
            configDir = "/home/magicbox/config/mylar";
            volumes = [
              "/mnt/extra/media:/data"
              "/mnt/nzbdav:/mnt/nzbdav:rshared"
            ];
          })
        ];
      };
      bazarr = {
        services = [
          (bazarr {
            domains = ["https://bazarr.szpunar.cloud" "https://bazarr.nea.rip"];
            networks = ["magicbox-network"];
            configDir = "/home/magicbox/config/bazarr";
            ports = ["6767:6767"];
            volumes = [
              "/mnt/extra/media:/data"
              "/mnt/nzbdav:/mnt/nzbdav:rshared"
            ];
          })
        ];
      };
      sabnzbd = {
        services = [
          (sabnzbd {
            domains = ["https://sabnzbd.szpunar.cloud" "https://sabnzbd.nea.rip"];
            networks = ["magicbox-network"];
            configDir = "/home/magicbox/config/sabnzbd";
            volumes = [
              "/mnt/extra/media/usenet:/data/usenet:rw"
            ];
          })
        ];
      };
      postgres = {
        services = [
          (postgres {
            networks = ["magicbox-network"];
            restart = "unless-stopped";
            user = "1000:100";
            ports = ["5432:5432"];
            dataDir = "/home/magicbox/data/postgres";
            configDir = "/home/magicbox/config/postgres";
            fileSecrets = {
              "/etc/postgresql/passwd" = "op://Secrets/MagicBox Container Postgres/password";
            };
            environment = {
              PUID = "1000";
              PGID = "100";
              TZ = "America/Indiana/Indianapolis";
              POSTGRES_PASSWORD_FILE = "/etc/postgresql/passwd";
            };
          })
        ];
      };
    };
  };
}
