{inputs, ...}: {
  flake.modules.nixos.leah-framework = {
    pkgs,
    ...
  }: {
    imports = with inputs.self.modules.nixos; [
      home-manager
      leah # (adds leah user + home manager config)
      inputs.nix-flatpak.nixosModules.nix-flatpak
    ];

    environment.systemPackages = with pkgs; [
      # Add your system packages here
    ];

    programs.nix-ld = {
      enable = true;
    };

    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM+9gEtoUZS0D6LAu7Jz8WnIRrKNna2zfH6F7QxzaeZa"
    ];

    users.users.leah = {
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };

    services.openssh.enable = true;
    services.openssh.settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };

    services.fwupd.enable = true;

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    boot.initrd.kernelModules = ["amdgpu"];

    boot.kernelPackages = pkgs.linuxPackages_latest;

    networking.networkmanager.enable = true;
    networking.networkmanager.wifi.backend = "iwd";
    networking.networkmanager.wifi.powersave = true;

    # Set your time zone.
    time.timeZone = "America/Indiana/Indianapolis";

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };

    services.fprintd.enable = true;

    # Enable the X11 windowing system.
    # services.xserver.enable = true;
    #     services.xserver.enable = true;
    services.xserver.videoDrivers = ["amdgpu"];

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # Enable CUPS to print documents.
    services.printing.enable = true;

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

    services.xserver.enable = true;
    services.xserver.xkb.options = "terminate:";
    services.displayManager.sddm = {
      theme = "breeze"; # -lavender";
      enable = false;
      enableHidpi = true;
      wayland.enable = true;
    };
    services.displayManager.cosmic-greeter.enable = true;

    services.tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
      extraSetFlags = [
        "--operator=leah"
      ];
    };
    networking.nameservers = [
      "100.100.100.100"
      "1.1.1.1"
    ];
    networking.search = ["risk-sidemirror.ts.net"];

    systemd.user.services.tailscale-systray = {
      enable = true;
      after = ["tailscaled.service"];
      wantedBy = ["default.target"];
      description = "Tailscale Systray";
      serviceConfig = {
        Type = "simple";
        ExecStart = ''${pkgs.unstable.tailscale}/bin/tailscale systray''; 
      };
    };

    system.autoUpgrade = {
      enable = true;
      flake = inputs.self.outPath;
      flags = [
        "--print-build-logs"
      ];
      dates = "04:00";
      randomizedDelaySec = "45min";
      allowReboot = true;
    };

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    nix.optimise.automatic = true;
    nix.optimise.dates = ["03:30"];

    # use gnome keyring
    services.gnome.gnome-keyring.enable = true;
    security.pam.services = {
      greetd.enableGnomeKeyring = true;
      greetd-password.enableGnomeKeyring = true;
      login.enableGnomeKeyring = true;
    };
    security.pam.services.swaylock = {};
    programs.seahorse.enable = true;
    security.polkit.enable = true;

    services.tlp.enable = false;
    services.tuned = {
      enable = true;
      ppdSupport = true;
    };

    services.cpupower-gui.enable = true;

    hardware.logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };

    services.geoclue2 = {
      submitData = true;
      submissionNick = "puppyleah";
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_QPA_PLATFORMTHEME = "qt5ct";
      QT_STYLE_OVERRIDE = "Fusion";
      QS_ICON_THEME = "WhiteSur-dark";
    };

    services.flatpak.enable = true;
    services.flatpak.packages = [
      "org.vinegarhq.Sober"
      "org.vinegarhq.Vinegar"
    ];

    services.hardware.bolt.enable = true;

    networking.firewall.enable = false;

    services.nextdns = {
      enable = true;
      arguments = ["-config" "3a5b4a" "-cache-size" "10MB"];
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
