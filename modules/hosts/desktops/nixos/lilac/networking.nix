{ ... }: {
  flake.modules.nixos.lilac-networking = { pkgs, ... }: {
    networking.networkmanager.enable = true;
    networking.networkmanager.wifi.backend = "iwd";
    networking.networkmanager.wifi.powersave = true;
    users.users.leah.extraGroups = [ "networkmanager" ];
    services.tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
      extraSetFlags = [ "--operator=leah" ];
    };
    environment.systemPackages = [ pkgs.nextdns ];
    networking.nameservers = [
      "100.100.100.100"
      "1.1.1.1"
    ];
    networking.search = [ "risk-sidemirror.ts.net" ];
    networking.firewall.enable = false;
    services.nextdns = {
      enable = true;
      arguments = [
        "-config"
        "3a5b4a"
        "-cache-size"
        "10MB"
      ];
    };
  };
}
