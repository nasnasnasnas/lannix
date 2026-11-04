{ inputs, ... }: {
  flake.modules.nixos.lilac =
    { pkgs, lib, ... }:
    let
      # Use the same pinned beta and Fish shell as nea-desktop.
      # Import/cache instructions: ../nea-desktop/README.md, CI source caching.
      tern = inputs.tern.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
        version = "0.9.10";
        src = pkgs.requireFile {
          name = "Tern-0.9.10-linux-x86_64.tar.gz";
          hash = "sha256-W9eCMo3w7iMw809gxAei8CUrrG6AbmINIrdEvOrUxtU=";
          message = ''
            Download Tern 0.9.10 from https://build.stencil.so/ and run:
              nix-prefetch-url file://$HOME/Downloads/Tern-0.9.10-linux-x86_64.tar.gz
            Push the imported archive to the lannix Attic cache for CI;
            see modules/hosts/desktops/nixos/nea-desktop/README.md.
          '';
        };
        installPhase =
          builtins.replaceStrings
            [ "--set SHELL ${old.passthru.loginShell}/bin/nu" ]
            [ "--set SHELL ${lib.getExe pkgs.fish}" ]
            old.installPhase;
        postFixup = (old.postFixup or "") + ''
          patchelf --add-rpath "${
            lib.makeLibraryPath [
              pkgs.pam
              pkgs.libpulseaudio
            ]
          }" "$out/opt/tern/tern"
        '';
      });
    in
    {
      environment.systemPackages = [
        tern
        (pkgs.makeDesktopItem {
          name = "so.stencil.tern";
          desktopName = "Tern";
          comment = "Stencil native workspace";
          exec = "${lib.getExe tern} %F";
          terminal = false;
          startupWMClass = "so.stencil.tern";
          categories = [
            "Development"
            "TerminalEmulator"
          ];
        })
      ];

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
          ExecStart = "${tern}/bin/tern remote serve --user";
          Restart = "on-failure";
          RestartSec = 2;
          RestartPreventExitStatus = 2;
          KillMode = "process";
          TimeoutStopSec = 10;
        };
      };
    };
}
