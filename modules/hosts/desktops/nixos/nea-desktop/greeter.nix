{inputs, ...}: {
  flake.modules.nixos.nea-desktop = {pkgs, ...}: {
    imports = [inputs.noctalia-greeter.nixosModules.default];

    services.displayManager.noctalia-greeter = {
      enable = true;
      passwordless-sync-users = ["nea"];
      # Appearance is supplied by Noctalia's sync.toml so subsequent palette,
      # wallpaper, font, and monitor changes follow the desktop automatically.
      settings = {
        session.default = "niri";
        user.default = "nea";
        clock.time_format = "{:%I:%M %p}";
        keyboard = {
          layout = "us";
          numlock = true;
        };
        cursor = {
          theme = "breeze_cursors";
          size = 24;
          path = pkgs.kdePackages.breeze;
        };
      };
    };

    security.pam.services = {
      greetd = {
        enableGnomeKeyring = true;
        fprintAuth = false;
      };
      greetd-password = {
        enableGnomeKeyring = true;
        fprintAuth = false;
      };
    };
  };
}
