{ inputs, ... }: {
  # Terminal-only identity: workstation tools, GUI configuration and Git signing
  # are selected separately by desktop hosts.
  # Before activation, check lavender, /home/lavender and /srv/shared for conflicts
  # and confirm wheel sudo requires a password. Retain an existing root session.
  # After activation, run `passwd lavender` interactively on EACH server through
  # retained admin access. Never store a password/hash here; mutableUsers must
  # remain true. Personal homes are not covered by the shared-data backups.
  flake.modules.nixos.lavender-server = { pkgs, ... }: {
    imports = [ inputs.self.modules.nixos.home-manager ];
    programs.fish.enable = true;
    users.users.lavender = {
      isNormalUser = true;
      description = "Lavender";
      home = "/home/lavender";
      homeMode = "0700";
      shell = pkgs.fish;
      extraGroups = [
        "wheel"
        "docker"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5TLqC2CVL78/Clc5Rc4FKQGJP1FbUKpV7N1kU/+WIw"
      ];
    };
    nix.settings.trusted-users = [ "lavender" ];
    home-manager.users.lavender = {
      imports = [ inputs.self.modules.homeManager.leah ];
      home.username = "lavender";
    };
  };
}
