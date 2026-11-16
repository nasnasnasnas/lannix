{...}: {
  flake.modules.nixos.nea-desktop = {config, ...}: {
    # Never open VNC on the LAN or public interfaces.
    networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [5900];
  };

  flake.modules.homeManager.nea-desktop = {
    services.wayvnc = {
      enable = true;
      autoStart = true;
      systemdTarget = "graphical-session.target";
      settings = {
        # This node's stable Tailscale IPv4; update after deleting/re-enrolling it.
        # Tailscale authenticates/encrypts access; do not bind a wildcard address.
        address = "100.116.128.43";
        port = 5900;
        enable_auth = false;
      };
    };

    systemd.user.services.wayvnc = {
      Unit = {
        ConditionEnvironment = "XDG_CURRENT_DESKTOP=niri";
        # Login can precede tailscaled bringing up the bound address.
        StartLimitIntervalSec = 0;
      };
      Service = {
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
