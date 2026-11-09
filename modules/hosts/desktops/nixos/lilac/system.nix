{ inputs, ... }: {
  flake.modules.nixos.lilac-system = { pkgs, ... }: {
    imports = [ inputs.bootvine.nixosModules.default ];
    nix.settings.trusted-users = [ "leah" ];
    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM+9gEtoUZS0D6LAu7Jz8WnIRrKNna2zfH6F7QxzaeZa"
    ];
    users.users.leah.extraGroups = [
      "wheel"
      "docker"
    ];
    services.openssh.enable = true;
    services.openssh.settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    services.bootvine.enable = true;
    boot.initrd.systemd.enable = true;
    nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.default ];
    boot.kernelPackages = pkgs.cachyosKernels."linuxPackages-cachyos-latest-lto-zen4";
    time.timeZone = "America/Indiana/Indianapolis";
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
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    nix.optimise.automatic = true;
    nix.optimise.dates = [ "03:30" ];
    virtualisation.docker.enable = true;
  };
}
