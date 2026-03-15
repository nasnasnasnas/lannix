{
  inputs,
  self,
  ...
}: let
  username = "leah";
in {
  flake.modules.nixos."${username}" = {pkgs, ...}: {
    # Install firefox.
    programs.firefox.enable = true;
    programs._1password.enable = true;
    programs._1password-gui.enable = true;
    programs._1password-gui.polkitPolicyOwners = ["leah"];
    programs.steam.enable = true;
    programs.steam.package = pkgs.steam.override {
      extraPkgs = pkgs': with pkgs'; [
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

    environment.etc = {
      "1password/custom_allowed_browsers" = {
        text = ''
          zen-beta
          zen
        '';
        mode = "0755";
      };
    };

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
      #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      wget
      git
      gh
      unstable.bun
      unstable.nodejs_24
      vscode-fhs
      ghostty
      alacritty
      vesktop
      unstable.element-desktop
      unstable.nheko
      # unstable.fluffychat
      microsoft-edge
      fastfetch
      hyfetch
      prismlauncher
      lunar-client
      powertop
      rustup
      epiphany
      seahorse
      (catppuccin-sddm.override {
        flavor = "mocha";
        accent = "lavender";
        font = "Noto Sans";
        fontSize = "13";
          background = "${./nas-flag-wallpaper.png}";
        loginBackground = true;
      })

      inputs.zen-browser.packages."${system}".default
      unstable.floorp-bin
      unstable.ollama
      unstable.kdePackages.kamoso
      cheese
      wl-clipboard
      libreoffice-fresh
      # libreoffice-collabora
      onlyoffice-desktopeditors
      rustup
      clang
      github-desktop
      gh
      fuzzel
      waybar

      nil
      nixd
      powershell
      xwayland-satellite
      # swaylock
      swayidle
      # mako
      xeyes
      gimp3
      android-studio
      brightnessctl
      polkit_gnome

      # kde stuff
      kdePackages.ark
      kdePackages.gwenview
      kdePackages.okular
      kdePackages.kate
      kdePackages.ktexteditor
      kdePackages.dolphin
      kdePackages.dolphin-plugins

      unstable.protonup-qt
      unstable.protontricks
      libnotify
      flyctl

      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
      whitesur-icon-theme
      flameshot
      easyeffects

      nextdns
      bottles

      zulu25

      unstable.claude-code-bin

      unstable.jetbrains.webstorm
      unstable.jetbrains.idea
      unstable.jetbrains.rider
      unstable.antigravity-fhs

      inputs.fresh.packages.${pkgs.stdenv.hostPlatform.system}.default

      btop
    ];

    programs.zsh.enable = true;

    programs.alvr.enable = true;

    # Enable the COSMIC desktop environment
    services.desktopManager.cosmic.enable = true;
    programs.niri.enable = true;

    programs.direnv.enable = true;

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
  };
}
