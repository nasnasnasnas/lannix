{ ... }: {
  flake.modules.nixos.lilac = { pkgs, lib, ... }: let
    # The closed-beta download stays outside the store: CI builds only this launcher.
    # Install/update without rebuilding NixOS:
    #   mkdir -p ~/.local/share
    #   tar -xzf ~/Downloads/Tern-VERSION-linux-x86_64.tar.gz -C ~/.local/share
    # Or extract into $XDG_DATA_HOME when it is set. The archive contains tern/tern.
    runtimeLibraries = lib.makeLibraryPath (with pkgs; [
      stdenv.cc.cc.lib
      libxcb
      libxkbcommon
      wayland
      vulkan-loader
      libglvnd
      libpulseaudio
      pipewire
      pam
      webkitgtk_4_1
    ]);
    tern = pkgs.writeShellScriptBin "tern" ''
      binary="''${XDG_DATA_HOME:-$HOME/.local/share}/tern/tern"
      if [ ! -x "$binary" ]; then
        printf 'Tern binary missing: %s\nExtract the Linux x86_64 archive into %s/.. first.\n' "$binary" "$(dirname "$binary")" >&2
        exit 1
      fi
      export LD_LIBRARY_PATH="${runtimeLibraries}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      # Run the ELF itself through nix-ld so /proc/self/exe stays Tern.
      # Invoking ld.so explicitly breaks Tern's generated services and re-exec.
      export NIX_LD="${pkgs.stdenv.cc.bintools.dynamicLinker}"
      export NIX_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
      exec "$binary" "$@"
    '';
  in {
    environment.systemPackages = [
      tern
      (pkgs.makeDesktopItem {
        name = "so.stencil.tern";
        desktopName = "Tern";
        comment = "Stencil native workspace";
        exec = "${tern}/bin/tern %F";
        terminal = false;
        startupWMClass = "so.stencil.tern";
        categories = [ "Development" "TerminalEmulator" ];
      })
    ];

    # Keep the remote service on the wrapper, including after beta binary updates.
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
