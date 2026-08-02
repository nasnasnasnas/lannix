{...}: {
  flake.modules.nixos.magicbox = {pkgs, ...}: let
    mountConsumerUnits = map (project: "magicbox-${project}.service") [
      "media"
      "sonarr"
      "radarr"
      "lidarr"
      "mylar"
      "bazarr"
    ];
  in {
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
        /home/magicbox/data/{caddy,jellyfin,postgres,termix,zurg-testing} \
        /home/magicbox/media/usenet \
        /home/magicbox/manual-media

      # Set ownership for local directories
      chown -R 1000:100 /home/magicbox/config || true
      chown -R 1000:100 /home/magicbox/data || true
      chown -R 1000:100 /home/magicbox/media || true
      chown -R 1000:100 /home/magicbox/manual-media || true
      chmod -R 755 /home/magicbox/config || true
      chmod -R 755 /home/magicbox/data || true
      chmod -R 755 /home/magicbox/media || true
      chmod -R 755 /home/magicbox/manual-media || true

      # Set ownership on /mnt mountpoints only while UNMOUNTED. A live mount is
      # owned by its own filesystem; recursing into one (especially a wedged
      # rclone FUSE backend) makes chown/chmod block forever in the kernel and
      # stalls every activation. Reading /proc/mounts never touches the mount.
      mounts="$(cat /proc/mounts)"
      for mp in /mnt/zurg /mnt/nzbdav /mnt/extra /mnt/windows; do
        case " $mounts " in
          *" $mp "*) continue ;;
        esac
        mkdir -p "$mp" || true
        chown 1000:100 "$mp" || true
        chmod 755 "$mp" || true
      done
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
      before = mountConsumerUnits;
      wantedBy = mountConsumerUnits;
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

    server-observability.enable = true;

    system.stateVersion = "25.05";
  };
}
