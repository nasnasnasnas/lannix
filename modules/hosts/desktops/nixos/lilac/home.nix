{ inputs, ... }: {
  flake.modules.homeManager.leah-lilac = { pkgs, lib, ... }: {
    imports = with inputs.self.modules.homeManager; [
      leah-lilac-easyeffects
      leah-lilac-umbriel
    ];
    home.packages = [ pkgs.ddcutil ];
    systemd.user.services.tailscale-systray = {
      Unit = {
        Description = "Tailscale Systray";
        After = [ "tailscaled.service" ];
      };
      Install.WantedBy = [ "default.target" ];
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.unstable.tailscale}/bin/tailscale systray";
      };
    };
    # Native clients connect as leah@lilac:8376 over Tailscale (UDP/QUIC).
    # User mode retains Tern's ~/.ssh/authorized_keys authentication policy.
    # Diagnose locally with: tern remote doctor leah@127.0.0.1
    systemd.user.services.tern-remote = {
      Unit = {
        Description = "Tern remote sessions";
        ConditionUser = "leah";
      };
      Install.WantedBy = [ "default.target" ];
      Service = {
        Type = "exec";
        ExecStart = "${lib.getExe pkgs.tern} remote serve --user";
        Restart = "on-failure";
        RestartSec = 2;
        RestartPreventExitStatus = 2;
        KillMode = "process";
        TimeoutStopSec = 10;
      };
    };
  };
}
