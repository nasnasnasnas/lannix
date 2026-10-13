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
    programs.steam.protontricks.enable = true;
    programs.gamescope = {
      enable = true;
      capSysNice = false;
    };

    services.displayManager.sddm = {
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
  };
}