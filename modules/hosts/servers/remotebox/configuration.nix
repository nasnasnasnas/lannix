{inputs, ...}: {
  flake.modules.nixos.remotebox = {pkgs, ...}: let
    opencodeOverlay = final: _prev: {
      opencode = final.stdenvNoCC.mkDerivation {
        pname = "opencode";
        version = "1.14.28";

        src = final.fetchurl {
          url = "https://github.com/anomalyco/opencode/releases/download/v1.14.28/opencode-linux-x64.tar.gz";
          hash = "sha256-P5pxOWEtRCGkZAjUbu7Se9lYvb5/Q1FM1eWhCtFUDls=";
        };

        nativeBuildInputs = [final.makeBinaryWrapper];

        dontUnpack = true;

        installPhase = ''
          runHook preInstall

          tar -xzf $src
          install -Dm755 opencode $out/bin/opencode
          wrapProgram $out/bin/opencode \
            --prefix PATH : ${final.lib.makeBinPath [final.ripgrep]}

          runHook postInstall
        '';
      };
    };

    unstable = import inputs.nixpkgs-unstable {
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (pkgs) config;
      overlays = [opencodeOverlay];
    };
  in {
    system.activationScripts.directoryConfig.text = ''
      mkdir -p /home/magicbox/data/wokecraft
      chown 1000:100 /home/magicbox/data/wokecraft || true
      chmod 755 /home/magicbox/data/wokecraft || true
    '';

    # imports = with inputs.self.modules.nixos; [
    #   system-cli
    #   systemd-boot
    #   impermanence
    # ];

    # imports = [
    #   #inputs.arion.nixosModules.arion
    # ];

    server-observability = {
      enable = true;
      extraPrometheusScrapeTargets = {
        minecraft = ["127.0.0.1:8080"];
        minecraft_details = ["127.0.0.1:19565"];
      };
      extraPrometheusScrapeTargetLabels.minecraft_details.instance = "wokecraft";
      dockerLogContainers = ["wokecraft"];
    };

    environment.systemPackages = with pkgs;
      [
        git
        wget
        curl
        btop
        fastfetch
        hyfetch
        nixd
        ripgrep
        rustc
        htop
        ffmpeg-full
        dua
        postgresql
        nodejs
        screen
      ]
      ++ (with unstable; [
        bun
        opencode
        git-credential-oauth
        fresh-editor
      ]);

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    nix.settings.trusted-users = ["magicbox"];

    services.dbus.packages = [pkgs.systemd];

    programs.nix-ld = {
      enable = true;
    };

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
      ClientAliveInterval = 60;
      ClientAliveCountMax = 10;
    };

    # Tailscale
    networking.firewall.checkReversePath = "loose";
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "server";
    };

    networking.firewall.allowedTCPPorts = [
      22
      80
      443
      25565 # wokecraft
    ];

    host.caddyDomains = ["https://wokecraft.szpunar.cloud"];

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "24.11"; # Did you read the comment?
  };
}
