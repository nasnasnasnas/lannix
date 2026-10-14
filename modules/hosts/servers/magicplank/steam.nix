{inputs, ...}: {
  flake-file.inputs = {
    json2steamshortcut = {
      url = "github:ChrisOboe/json2steamshortcut";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  flake.modules.nixos.magicplank = {
    pkgs,
    lib,
    ...
  }: {
    imports = [inputs.self.modules.nixos.home-manager inputs.jovian.nixosModules.jovian];

    home-manager.users.steamuser = {
      imports = [inputs.json2steamshortcut.homeModules.default];
      home.stateVersion = "26.05";

      services.steam-shortcuts = {
        enable = true;
        # Owns the entire non-Steam shortcut list; add future entries below.
        # Exit Steam before rebuilding, then reopen it to load the new VDF.
        overwriteExisting = true;
        # Numeric userdata directory from Magicplank's steamuser account.
        steamUserId = 336245150;
        shortcuts = [
          {
            AppName = "VacuumTube";
            Exe = lib.getExe pkgs.unstable.vacuum-tube;
            StartDir = "/home/steamuser";
            # Keep Steam's injected libraries out of Electron.
            LaunchOptions = "LD_PRELOAD= LD_LIBRARY_PATH= %command% --fullscreen";
            Icon = "${pkgs.unstable.vacuum-tube}/share/icons/hicolor/256x256/apps/rocks.shy.VacuumTube.png";
            Tags = ["Media"];
          }
        ];
      };
    };

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
    # programs.steam.gamescopeSession.args = ["-h" "1080"];
    programs.steam.gamescopeSession.env = {
      STEAM_ENABLE_CEC = "1";
    };
    programs.steam.protontricks.enable = true;
    programs.gamescope = {
      enable = true;
      capSysNice = false;
    };

    jovian.decky-loader.enable = true;
    jovian.steamos.enableHdmiCecIntegration = true;

    programs.gamemode = {
      enable = true;
      enableRenice = true;
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
      extraRules = [
        {
          "name" = "gamescope";
          "nice" = -20;
        }
      ];
    };

    environment.systemPackages = with pkgs; [
      mangohud
      unstable.vacuum-tube
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