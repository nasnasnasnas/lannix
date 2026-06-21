{inputs, ...}: {
  flake.modules.nixos.magicbox = inputs.self.lib.mkHostServices {
    publicIPs = ["10.177.177.117"];
    secretsEnvPath = "/var/lib/opnix/secrets/magicbox/caddy.env";
    networks = ["magicbox-network" "zurg"];
    services = with inputs.self.services; [
      (termix {
        domains = ["https://termix.szpunar.cloud"];
        networks = ["magicbox-network"];
        dataDir = "/home/magicbox/data/termix";
      })

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
        domains = ["https://nzbdav.szpunar.cloud"];
        networks = ["magicbox-network"];
        configDir = "/home/magicbox/config/nzbdav";
        volumes = [
          "/mnt/nzbdav:/mnt/nzbdav:rshared"
          "/home/magicbox/media:/data"
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
        domains = ["https://stream.szpunar.cloud"];
        networks = ["magicbox-network"];
        nvidia = true;
        depends_on = ["zurg" "rclone"];
        volumes = [
          "/home/magicbox/config/jellyfin:/config"
          "/home/magicbox/data/jellyfin:/cache"
          "/home/magicbox/media:/data"
          "/home/magicbox/manual-media:/data-ro"
          "/mnt/zurg:/media:rshared"
          "/mnt/nzbdav:/mnt/nzbdav:rshared"
        ];
      })

      (prowlarr {
        domains = ["https://prowlarr.szpunar.cloud"];
        networks = ["magicbox-network"];
        configDir = "/home/magicbox/config/prowlarr";
      })

      (sonarr {
        domains = ["https://sonarr.szpunar.cloud"];
        networks = ["magicbox-network"];
        configDir = "/home/magicbox/config/sonarr";
        volumes = [
          "/home/magicbox/media:/data"
          "/mnt/nzbdav:/mnt/nzbdav:rshared"
        ];
      })

      (radarr {
        domains = ["https://radarr.szpunar.cloud"];
        networks = ["magicbox-network"];
        configDir = "/home/magicbox/config/radarr";
        volumes = [
          "/home/magicbox/media:/data"
          "/mnt/nzbdav:/mnt/nzbdav:rshared"
        ];
      })

      (lidarr {
        domains = ["https://lidarr.szpunar.cloud"];
        networks = ["magicbox-network"];
        configDir = "/home/magicbox/config/lidarr";
        volumes = [
          "/home/magicbox/media:/data"
          "/mnt/nzbdav:/mnt/nzbdav:rshared"
        ];
      })

      (mylar {
        domains = ["https://mylar.szpunar.cloud"];
        networks = ["magicbox-network"];
        configDir = "/home/magicbox/config/mylar";
        volumes = [
          "/home/magicbox/media:/data"
          "/mnt/nzbdav:/mnt/nzbdav:rshared"
        ];
      })

      (bazarr {
        domains = ["https://bazarr.szpunar.cloud"];
        networks = ["magicbox-network"];
        configDir = "/home/magicbox/config/bazarr";
        ports = ["6767:6767"];
        volumes = [
          "/home/magicbox/media:/data"
          "/mnt/nzbdav:/mnt/nzbdav:rshared"
        ];
      })

      (sabnzbd {
        domains = ["https://sabnzbd.szpunar.cloud"];
        networks = ["magicbox-network"];
        configDir = "/home/magicbox/config/sabnzbd";
        volumes = [
          "/home/magicbox/media/usenet:/data/usenet:rw"
        ];
      })

      (grafana {
        domains = ["https://grafana.szpunar.cloud"];
        networks = ["magicbox-network"];
        dataDir = "/home/magicbox/data/grafana";
        adminPassword = null;
        env_file = ["/var/lib/opnix/secrets/magicbox/grafana.env"];
        plugins = [
          "grafana-pyroscope-app"
          "grafana-lokiexplore-app"
          "victoriametrics-logs-datasource"
          "victoriametrics-metrics-datasource"
        ];
      })

      (victoriametrics {
        domains = ["https://victoriametrics.szpunar.cloud"];
        networks = ["magicbox-network"];
        dataDir = "/home/magicbox/data/victoriametrics";
      })

      (victorialogs {
        domains = ["https://victorialogs.szpunar.cloud"];
        networks = ["magicbox-network"];
        dataDir = "/home/magicbox/data/victorialogs";
      })

      (pyroscope {
        domains = ["https://pyroscope.szpunar.cloud"];
        networks = ["magicbox-network"];
        dataDir = "/home/magicbox/data/pyroscope";
      })

      (postgres {
        networks = ["magicbox-network"];
        restart = "unless-stopped";
        user = "1000:100";
        ports = ["5432:5432"];
        dataDir = "/home/magicbox/data/postgres";
        configDir = "/home/magicbox/config/postgres";
        environment = {
          PUID = "1000";
          PGID = "100";
          TZ = "America/Indiana/Indianapolis";
          POSTGRES_PASSWORD_FILE = "/etc/postgresql/passwd";
        };
      })
    ];
  };
}
