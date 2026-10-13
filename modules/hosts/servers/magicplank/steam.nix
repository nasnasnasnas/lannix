{inputs, ...}: {
  flake.modules.nixos.magicplank = {
    pkgs,
    lib,
    ...
  }: {
    users.users.steamuser = {
      isNormalUser = true;
      description = "steamuser";
      extraGroups = ["wheel"];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM+9gEtoUZS0D6LAu7Jz8WnIRrKNna2zfH6F7QxzaeZa"
      ];
    };


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
    programs.steam.gamescopeSession.steamArgs = ["-steamos3" "-steamos" "-gamepadui"];
    programs.steam.gamescopeSession.env = {
      STEAM_ENABLE_CEC = "1";
    };
    programs.steam.protontricks.enable = true;
    programs.gamescope = {
      enable = true;
      capSysNice = false;
    };

    services.xserver.enable = true;
    services.displayManager.sddm = {
      # wayland.enable = true;
      enable = true;
      settings = {
        Autologin = {
          Session = "steam.desktop";
          User = "steamuser";
        };
      };
      autoLogin.relogin = true;
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

    environment.systemPackages = with pkgs; [
      mangohud
    ];

    # Enable sound with pipewire.
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };
  };
}