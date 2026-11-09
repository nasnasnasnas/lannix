{ inputs, ... }: {
  flake.modules.nixos.lilac-desktop = { pkgs, ... }: {
    imports = [
      inputs.nix-flatpak.nixosModules.nix-flatpak
      inputs.solaar.nixosModules.default
      inputs.noctalia-greeter.nixosModules.default
    ];
    environment.systemPackages = with pkgs; [
      (catppuccin-sddm.override {
        flavor = "mocha";
        accent = "lavender";
        font = "Noto Sans";
        fontSize = "13";
        background = "${../../../../users/leah/nas-flag-wallpaper.png}";
        loginBackground = true;
      })
    ];
    services.xserver.enable = true;
    services.xserver.xkb = {
      layout = "us";
      variant = "";
      options = "terminate:";
    };
    services.displayManager.sddm = {
      theme = "catppuccin-mocha-lavender";
      enable = false;
      enableHidpi = true;
      wayland.enable = true;
    };
    services.displayManager.noctalia-greeter = {
      enable = true;
      package = inputs.noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default;
      passwordless-sync-users = [ "leah" ];
      greeter-args = "--session Niri";
    };
    services.printing.enable = true;
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    services.gnome.gnome-keyring.enable = true;
    security.pam.services = {
      greetd = {
        enableGnomeKeyring = true;
        fprintAuth = false;
      };
      greetd-password = {
        enableGnomeKeyring = true;
        fprintAuth = false;
      };
      login.enableGnomeKeyring = true;
      sddm.enableGnomeKeyring = true;
      swaylock = { };
    };
    programs.seahorse.enable = true;
    security.polkit.enable = true;
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
  };
}
