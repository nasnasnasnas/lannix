{ inputs, ... }: {
  perSystem = { pkgs, lib, ... }: {
    packages.tern =
      inputs.tern.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
        (old: rec {
          version = "0.9.32";
          src = pkgs.requireFile {
            name = "Tern-${version}-linux-x86_64.tar.gz";
            hash = "sha256-qMq86ra+NbQB5pdn9RYB5/hC6vAB/OZVozR3E/jFH3Q=";
            message = ''
              From the repo root, run ./download-tern.mjs while signed in to
              https://build.stencil.so/ in Helium. Import the pinned archive:
                nix store add-file "$HOME/Downloads/Tern-${version}-linux-x86_64.tar.gz"
              For CI, also push the imported archive to Attic; see
              modules/hosts/desktops/nixos/nea-desktop/README.md.
            '';
          };
          # Retain upstream's WebKit/GIO environment, including its matching TLS backend.
          # Replace only the Nushell probe with Fish.
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
  };

  # mkNixos exposes perSystem packages through the host's pkgs overlay.
  flake.modules.nixos.tern = { pkgs, lib, ... }: {
    environment.systemPackages = [
      pkgs.tern
      (pkgs.makeDesktopItem {
        name = "so.stencil.tern";
        desktopName = "Tern";
        comment = "Stencil native workspace";
        # Upstream ships no icon; nea-desktop's macOS27 theme provides this name.
        icon = "so.stencil.tern";
        exec = "${lib.getExe pkgs.tern} %F";
        terminal = false;
        startupWMClass = "so.stencil.tern";
        categories = [
          "Development"
          "TerminalEmulator"
        ];
      })
    ];
  };
}
