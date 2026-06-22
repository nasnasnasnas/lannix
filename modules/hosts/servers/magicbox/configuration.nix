{...}: {
  flake.modules.nixos.magicbox = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      git
      wget
      curl
      btop
      fastfetch
      hyfetch
      nixd
      ripgrep
      htop
      ffmpeg-full
      dua
      fd
      damon
    ];

    nix.settings.trusted-users = ["nixos" "nea" "magicbox"];

    programs.nix-ld.enable = true;

    system.activationScripts.directoryConfig.text = ''
      # Ensure bind-mount and mountpoint directories exist
      mkdir -p \
        /home/magicbox/config/{bazarr,jellyfin,lidarr,mylar,nzbdav,postgres,prowlarr,radarr,rclone-nzbdav,sabnzbd,sonarr,zurg-testing} \
        /home/magicbox/data/{caddy,grafana,jellyfin,postgres,pyroscope,termix,victorialogs,victoriametrics,zurg-testing} \
        /home/magicbox/media/usenet \
        /home/magicbox/manual-media \
        /mnt/{extra,nzbdav,windows,zurg}

      # Set ownership for local directories
      chown -R 1000:100 /home/magicbox/config || true
      chown -R 1000:100 /home/magicbox/data || true
      chown -R 1000:100 /home/magicbox/media || true
      chown -R 1000:100 /home/magicbox/manual-media || true
      chmod -R 755 /home/magicbox/config || true
      chmod -R 755 /home/magicbox/data || true
      chmod -R 755 /home/magicbox/media || true
      chmod -R 755 /home/magicbox/manual-media || true

      chown -R 1000:100 /mnt/zurg || true
      chmod -R 755 /mnt/zurg || true
      chown -R 1000:100 /mnt/nzbdav || true
      chmod -R 755 /mnt/nzbdav || true
      chown -R 1000:100 /mnt/extra || true
      chmod -R 755 /mnt/extra || true
      chown -R 1000:100 /mnt/windows || true
      chmod -R 755 /mnt/windows || true
    '';

    users.users.magicbox = {
      isNormalUser = true;
      description = "magicbox";
      extraGroups = ["networkmanager" "wheel" "docker"];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM+9gEtoUZS0D6LAu7Jz8WnIRrKNna2zfH6F7QxzaeZa"
      ];
    };

    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM+9gEtoUZS0D6LAu7Jz8WnIRrKNna2zfH6F7QxzaeZa"
    ];

    services.openssh.enable = true;
    services.openssh.settings.PermitRootLogin = "yes";

    networking.firewall.checkReversePath = "loose";
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "server";
    };

    programs.fuse.enable = true;
    programs.fuse.userAllowOther = true;

    networking.firewall.allowedTCPPorts = [22 80 443 5432 6767];

    systemd.services.magicbox-stale-mount-cleanup = {
      description = "Clean up stale Magicbox rclone mountpoints";
      before = ["magicbox.service"];
      wantedBy = ["magicbox.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "magicbox-stale-mount-cleanup" ''
          cleanup_mount() {
            local mountpoint="$1"

            if ${pkgs.util-linux}/bin/mountpoint -q "$mountpoint" && ! ${pkgs.coreutils}/bin/stat "$mountpoint" >/dev/null 2>&1; then
              ${pkgs.util-linux}/bin/umount -l "$mountpoint" || true
            fi

            ${pkgs.coreutils}/bin/mkdir -p "$mountpoint"
            ${pkgs.coreutils}/bin/chown 1000:100 "$mountpoint" || true
            ${pkgs.coreutils}/bin/chmod 755 "$mountpoint" || true
          }

          cleanup_mount /mnt/nzbdav
          cleanup_mount /mnt/zurg
        '';
      };
    };

    systemd.services.magicbox = {
      after = ["magicbox-stale-mount-cleanup.service"];
      wants = ["magicbox-stale-mount-cleanup.service"];
    };

    services.alloy.enable = true;
    environment.etc."alloy/config.alloy".text = ''
      prometheus.exporter.self "default" {

      }

      prometheus.scrape "metamonitoring" {
        targets    = prometheus.exporter.self.default.targets
        forward_to = [prometheus.remote_write.default.receiver]
      }

      prometheus.remote_write "default" {
        endpoint {
          url = "https://victoriametrics.szpunar.cloud/prometheus/api/v1/write"
        }
      }

      logging {
      //   level    = "<LOG_LEVEL>"
      //   format   = "<LOG_FORMAT>"
        write_to = [loki.write.default.receiver]
      }

      loki.write "default" {
        endpoint {
          url = "https://victorialogs.szpunar.cloud/insert/loki/api/v1/push"
        }
      }
    '';

    system.stateVersion = "25.05";
  };
}
