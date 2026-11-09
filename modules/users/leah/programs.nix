{ inputs, ... }: {
  flake.modules.nixos.leah-desktop = { pkgs, ... }: {
    home-manager.users.leah.imports = with inputs.self.modules.homeManager; [
      leah-tools-linux
      leah-desktop-linux
    ];
    fonts.enableDefaultPackages = true;
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      nerd-fonts.jetbrains-mono
    ];
    # Install firefox.
    programs.firefox.enable = true;
    programs._1password.enable = true;
    programs._1password-gui.enable = true;
    programs._1password-gui.polkitPolicyOwners = [ "leah" ];
    programs.steam.enable = true;
    programs.steam.package = pkgs.steam.override {
      extraPkgs =
        pkgs': with pkgs'; [
          libxcursor
          libxi
          libxinerama
          libxscrnsaver
          libpng
          libpulseaudio
          libvorbis
          stdenv.cc.cc.lib # Provides libstdc++.so.6
          libkrb5
          keyutils
          # Add other libraries as needed
        ];
    };
    programs.kdeconnect.enable = true;
    programs.localsend.enable = true;

    environment.etc = {
      "1password/custom_allowed_browsers" = {
        text = ''
          zen-beta
          zen
          vivaldi
        '';
        mode = "0755";
      };
    };

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
      powertop
      xwayland-satellite
      polkit_gnome
    ];

    programs.zsh.enable = true;

    programs.alvr.enable = true;

    # Enable the COSMIC desktop environment
    services.desktopManager.cosmic.enable = true;
    environment.cosmic.excludePackages = [ pkgs.networkmanagerapplet ];
    programs.niri.enable = true;

    programs.gamescope = {
      enable = true;
      capSysNice = false;
    };
    programs.steam.gamescopeSession.enable = true;

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

    programs.librepods.enable = true;
    users.users.leah.extraGroups = [ "librepods" ];
  };
  flake.modules.homeManager.leah-desktop-linux = { pkgs, ... }: {
    home.packages = with pkgs; [
      unstable.vscode-fhs
      alacritty
      unstable.element-desktop
      unstable.nheko
      microsoft-edge
      prismlauncher
      lunar-client
      epiphany
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
      unstable.floorp-bin
      unstable.ollama
      unstable.kdePackages.kamoso
      cheese
      wl-clipboard
      libreoffice-fresh
      onlyoffice-desktopeditors
      github-desktop
      fuzzel
      waybar
      swayidle
      xeyes
      gimp3
      android-studio
      brightnessctl
      kdePackages.ark
      kdePackages.gwenview
      kdePackages.okular
      kdePackages.kate
      kdePackages.ktexteditor
      kdePackages.dolphin
      kdePackages.dolphin-plugins
      nautilus
      unstable.protonup-qt
      unstable.protontricks
      libnotify
      gpu-screen-recorder
      whitesur-icon-theme
      unstable.flameshot
      bottles
      unstable.jetbrains.webstorm
      unstable.jetbrains.idea
      unstable.jetbrains.rider
      unstable.jetbrains.rust-rover
      unstable.jetbrains.clion
      unstable.jetbrains.phpstorm
      unstable.jetbrains.goland
      unstable.antigravity-ide-fhs
      zotero
      inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.radaromega
      (unstable.vivaldi.override {
        enableWidevine = true;
        proprietaryCodecs = true;
        inherit widevine-cdm vivaldi-ffmpeg-codecs;
      })
      unstable.obsidian
      inputs.cider.packages.${pkgs.stdenv.hostPlatform.system}.cider
      freecad
      unstable.signal-desktop
    ];
  };
}
