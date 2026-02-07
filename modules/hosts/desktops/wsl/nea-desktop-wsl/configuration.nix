{inputs, ...}: {
  flake.modules.nixos.nea-desktop-wsl = {pkgs, ...}: {
    imports = with inputs.self.modules.nixos; [
      inputs.nixos-wsl.nixosModules.default
      home-manager
      # leah (adds leah user + home manager config)
    ];

    wsl.enable = true;
    wsl.defaultUser = "nixos";

    environment.systemPackages = with pkgs; [
      # Add your system packages here
      git
      wget
      curl
      btop
      fastfetch
      nixd
    ];

    programs.nix-ld = {
      enable = true;
    };

    virtualisation.docker.enable = true;
    users.extraUsers.nixos.extraGroups = ["docker"];

    users.extraUsers.nixos.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM+9gEtoUZS0D6LAu7Jz8WnIRrKNna2zfH6F7QxzaeZa"
    ];

    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM+9gEtoUZS0D6LAu7Jz8WnIRrKNna2zfH6F7QxzaeZa"
    ];

    services.openssh.enable = true;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "24.11"; # Did you read the comment?
  };
}
