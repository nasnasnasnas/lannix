{ inputs, ... }: {
  flake.modules.nixos.lilac =
    { pkgs, lib, ... }:
    {
      imports = [ inputs.self.modules.nixos.tern ];

      # Keep remote sessions on the same packaged Tern as the desktop.
      # Native clients connect as leah@lilac:8376 over Tailscale (UDP/QUIC).
      # User mode retains Tern's ~/.ssh/authorized_keys authentication policy.
      # Diagnose locally with: tern remote doctor leah@127.0.0.1
      systemd.user.services.tern-remote = {
        description = "Tern remote sessions";
        wantedBy = [ "default.target" ];
        unitConfig.ConditionUser = "leah";
        serviceConfig = {
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
