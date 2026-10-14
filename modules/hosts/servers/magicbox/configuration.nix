{...}: {
  flake.modules.nixos.magicbox = {
    lib,
    pkgs,
    ...
  }: let
    # The media project owns the rclone FUSE mounts. The other projects bind them.
    mountOwnerUnit = "magicbox-media";
    mountConsumerUnits = map (project: "magicbox-${project}") [
      "sonarr"
      "radarr"
      "lidarr"
      "mylar"
      "bazarr"
    ];

    # A killed rclone leaves its mount behind, and every stat on it fails with
    # ENOTCONN. That breaks `mountpoint` and Docker bind mounts alike. findmnt
    # reads the mount table without touching the mount, so it still finds the
    # dead entry for a lazy unmount.
    staleMountCleanup = pkgs.writeShellScript "magicbox-stale-mount-cleanup" ''
      for mountpoint in /mnt/nzbdav /mnt/zurg; do
        while ${pkgs.util-linux}/bin/findmnt -rn --mountpoint "$mountpoint" >/dev/null \
          && ! ${pkgs.coreutils}/bin/stat "$mountpoint" >/dev/null 2>&1; do
          echo "Lazily unmounting dead mount $mountpoint"
          ${pkgs.util-linux}/bin/umount -l "$mountpoint" || break
        done

        if ! ${pkgs.util-linux}/bin/findmnt -rn --mountpoint "$mountpoint" >/dev/null; then
          ${pkgs.coreutils}/bin/mkdir -p "$mountpoint"
          ${pkgs.coreutils}/bin/chown 1000:100 "$mountpoint"
          ${pkgs.coreutils}/bin/chmod 755 "$mountpoint"
        fi
      done
    '';
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

    systemd.services =
      {
        # Systemd signals the whole cgroup on stop, so docker compose sees a
        # second signal and SIGKILLs every container. An explicit compose stop
        # gives rclone its grace period to unmount cleanly.
        ${mountOwnerUnit}.serviceConfig = {
          ExecStartPre = [staleMountCleanup];
          ExecStop = pkgs.writeShellScript "${mountOwnerUnit}-stop" ''
            exec arion --prebuilt-file "$ARION_PREBUILT" stop
          '';
        };
      }
      # Ordering after the owner makes consumers stop first, which releases
      # their bind mounts before rclone tries to unmount.
      // lib.genAttrs mountConsumerUnits (_: {
        after = ["${mountOwnerUnit}.service"];
        serviceConfig.ExecStartPre = [staleMountCleanup];
      });

    server-observability.enable = true;

    system.stateVersion = "25.05";
  };
}
