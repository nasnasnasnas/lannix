{inputs, ...}: {
  flake.modules.nixos.nea-desktop = {
    pkgs,
    lib,
    ...
  }: {
    imports = with inputs.self.modules.nixos; [
      home-manager
      nea
      inputs.nix-flatpak.nixosModules.nix-flatpak
    ];

    home-manager.users.nea.imports = [inputs.self.modules.homeManager.nea-desktop];
    home-manager.backupCommand = lib.mkForce null;
    home-manager.backupFileExtension = lib.mkForce "lannix-backup";
    home-manager.overwriteBackup = lib.mkForce false;
    users.users.nea = {
      description = "Nea Szpunar";
      extraGroups = ["networkmanager" "wheel" "kvm" "libvirtd"];
    };
    users.users.leah = {
      isNormalUser = true;
      description = "Leah Szpunar";
      shell = pkgs.fish;
      extraGroups = ["networkmanager" "wheel" "kvm" "libvirtd"];
    };

    networking.networkmanager = {
      enable = true;
      wifi.backend = "iwd";
      wifi.powersave = false;
      # Ignore DHCP-provided resolvers; the router hands out a flaky NextDNS
      # primary that drops queries and stalls lookups for the 5s resolver timeout.
      dns = "none";
    };
    networking.nameservers = ["1.1.1.1" "1.0.0.1"];
    services.tailscale = {
      enable = true;
      extraSetFlags = ["--operator=nea"];
    };
    time.timeZone = "America/Indiana/Indianapolis";
    i18n.defaultLocale = "en_US.UTF-8";
    services.xserver = {
      enable = true;
      videoDrivers = ["amdgpu"];
      xkb = {
        layout = "us";
        options = "terminate:";
      };
    };
    services.desktopManager.cosmic.enable = false;
    services.displayManager.cosmic-greeter.enable = false;
    programs.niri.enable = true;
    programs.dconf.enable = true;
    hardware.bluetooth.enable = true;
    services.upower.enable = true;
    services.gvfs.enable = true;
    # GNOME Files loads Ghostty's bundled "Open in Ghostty" context-menu
    # action (share/nautilus-python/extensions/ghostty.py, installed by Home
    # Manager's programs.ghostty) through nautilus-python; see
    # NAUTILUS_4_EXTENSION_DIR below.
    xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];

    # All three panels (ASUS PB277, 2x LG Ultra HD) are RGB-stripe; render
    # ClearType-style subpixel text instead of the grayscale default.
    fonts.fontconfig = {
      subpixel.rgba = "rgb";
      subpixel.lcdfilter = "default";
      hinting.style = "slight";
      # Apple's system fonts (modules/apps/apple-fonts.nix) for every app that
      # asks fontconfig for a generic family; Noto still covers emoji and
      # scripts SF lacks.
      defaultFonts = {
        sansSerif = ["SF Pro Text"];
        serif = ["New York"];
        monospace = ["SF Mono"];
      };
    };
    fonts.packages = [pkgs.apple-fonts];

    services.fwupd.enable = true;
    services.fprintd.enable = true;
    services.printing.enable = true;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;
    security.polkit.enable = true;
    hardware.i2c.enable = true;
    hardware.logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
    services.tuned = {
      enable = true;
      ppdSupport = true;
    };
    services.cpupower-gui.enable = true;

    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = ["nea"];
    };
    environment.etc."1password/custom_allowed_browsers" = {
      text = "helium\n";
      mode = "0755";
    };
    programs.steam.enable = true;
    programs.kdeconnect.enable = true;
    programs.bash.enable = true;
    programs.zsh.enable = true;
    programs.nix-ld.enable = true;
    services.envfs.enable = true;

    virtualisation.libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
    };
    programs.virt-manager.enable = true;
    environment.variables.LIBVIRT_DEFAULT_URI = "qemu:///system";

    services.flatpak = {
      enable = true;
      packages = ["com.usebottles.bottles"];
    };
    environment.sessionVariables = {
      BROWSER = "helium";
      NIXOS_OZONE_WL = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_QPA_PLATFORMTHEME = "qt6ct";
      QT_STYLE_OVERRIDE = "kvantum";
      NAUTILUS_4_EXTENSION_DIR = "${pkgs.nautilus-python}/lib/nautilus/extensions-4";
    };

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 45d";
    };
    nix.optimise = {
      automatic = true;
      dates = ["03:30"];
    };
    # Rebuilds and scheduled upgrades now use the checkout in this repository.
    system.autoUpgrade = {
      enable = true;
      flake = "/home/nea/lannix#nea-desktop";
      flags = ["--print-build-logs"];
      dates = "04:00";
      randomizedDelaySec = "45min";
      allowReboot = true;
    };
    system.stateVersion = "25.05";
  };
}
