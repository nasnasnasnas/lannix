{...}: {
  flake.modules.nixos.remotebox = {pkgs, ...}: {
    # imports = with inputs.self.modules.nixos; [
    #   system-cli
    #   systemd-boot
    #   impermanence
    # ];

    # imports = [
    #   #inputs.arion.nixosModules.arion
    # ];

    environment.systemPackages = with pkgs; [
      git
      wget
      curl
      btop
      fastfetch
      hyfetch
      nixd
      ripgrep
      rustc
      bun
      htop
      ffmpeg-full
      dua
    ];

    nix.settings.trusted-users = ["magicbox"];

    programs.nix-ld = {
      enable = true;
    };

    # modules.fd.enable = true; # Enable fd file search

    users.users.magicbox = {
      isNormalUser = true;
      description = "magicbox";
      extraGroups = ["wheel" "docker"];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM+9gEtoUZS0D6LAu7Jz8WnIRrKNna2zfH6F7QxzaeZa"
      ];
    };

    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM+9gEtoUZS0D6LAu7Jz8WnIRrKNna2zfH6F7QxzaeZa"
    ];

    services.openssh.enable = true;
    services.openssh.settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = true;
    };

    # Tailscale
    networking.firewall.checkReversePath = "loose";
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "server";
    };

    networking.firewall.allowedTCPPorts = [22 80 443];

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "24.11"; # Did you read the comment?
  };
}
