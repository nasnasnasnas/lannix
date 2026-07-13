{inputs, ...}: {
  flake.modules.nixos.magicplank = {
    pkgs,
    lib,
    ...
  }: {
    # imports = with inputs.self.modules.nixos; [
    #   system-cli
    #   systemd-boot
    #   impermanence
    # ];

    # imports = [
    #   #inputs.arion.nixosModules.arion
    # ];

    environment.systemPackages = with pkgs; [
      git
      wget
      curl
      btop
      fastfetch
      hyfetch
      nixd
      ripgrep
      bun
      htop
      dua
      unstable.fresh-editor
      master.kdePackages.plasma-bigscreen
      master.kdePackages.plasma-nm
      unstable.vacuum-tube
    ];

    # Use nixpkgs-master only for kdePackages (Plasma 6 etc.)
    nixpkgs.overlays = [
      (final: _prev: {
        kdePackages = final.unstable.kdePackages;
      })
      inputs.nix-cachyos-kernel.overlays.default
    ];

    nix.settings.trusted-users = ["magicbox"];

    programs.nix-ld = {
      enable = true;
    };

    # nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.default ];
    boot.kernelPackages = pkgs.cachyosKernels."linuxPackages-cachyos-latest-lto-zen4";

    # nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
    # nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];

    # Set your time zone.
    time.timeZone = "America/Indiana/Indianapolis";

    # modules.fd.enable = true; # Enable fd file search

    users.users.magicbox = {
      isNormalUser = true;
      description = "magicbox";
      extraGroups = ["wheel" "docker"];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM+9gEtoUZS0D6LAu7Jz8WnIRrKNna2zfH6F7QxzaeZa"
      ];
    };

    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM+9gEtoUZS0D6LAu7Jz8WnIRrKNna2zfH6F7QxzaeZa"
    ];

    services.openssh.enable = true;
    services.openssh.settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    # Tailscale
    networking.firewall.checkReversePath = "loose";

    # LiveKit / Matrix-RTC media + TURNS (TURNS 5349 is published by caddy's layer4 listener,
    # 7881 + the 50100-50200/udp range are published directly by the livekit container).
    networking.firewall.allowedTCPPorts = [7881 5349];
    networking.firewall.allowedUDPPortRanges = [
      {
        from = 50100;
        to = 50200;
      }
    ];

    # for attic
    networking.hosts."127.0.0.1" = ["attic.szpunar.cloud"];

    # Caddy reverse-proxies this to off-host Home Assistant at 10.1.0.12:8123
    # (site block in services.nix caddy.globalConfig). Registered here so DNS
    # generation emits the home.szpunar.cloud A record -> this host's publicIPs.
    host.caddyDomains = ["https://home.szpunar.cloud"];
    services.resolved.enable = true;
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "server";
    };

    services.tlp.enable = false;
    powerManagement.cpuFreqGovernor = "performance";

    # services = {
    #   desktopManager.plasma6.enable = true;

    #   displayManager = {
    #     sddm.enable = true;
    #     sddm.wayland.enable = true;
    #     autoLogin.enable = true;
    #     autoLogin.user = "magicplank";
    #   };
    # };
    programs.kdeconnect.enable = true;

    programs.steam.package = pkgs.steam.override {
      extraPkgs = pkgs':
        with pkgs'; [
          libXcursor
          libXi
          libXinerama
          libXScrnSaver
          libpng
          libpulseaudio
          libvorbis
          stdenv.cc.cc.lib # Provides libstdc++.so.6
          libkrb5
          keyutils
          # Add other libraries as needed
        ];
    };
    programs.steam.enable = true;
    programs.steam.remotePlay.openFirewall = true;
    programs.steam.gamescopeSession.enable = true;
    programs.steam.protontricks.enable = true;
    programs.gamescope = {
      enable = true;
      capSysNice = false;
    };

    systemd.user.services.steam = {
      enable = true;
      description = "Open Steam in the background at boot";
      serviceConfig = {
        ExecStart = "${pkgs.steam}/bin/steam -nochatui -nofriendsui -silent %U";
        wantedBy = ["graphical-session.target"];
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    services.ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-cpp;
      extraRules = [
        {
          "name" = "gamescope";
          "nice" = -20;
        }
      ];
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "25.05"; # Did you read the comment?
  };
}
