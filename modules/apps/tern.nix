{ inputs, ... }: {
  perSystem = { pkgs, lib, ... }: {
    packages.tern =
      inputs.tern.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
        (old: {
          version = "0.9.12";
          src = pkgs.requireFile {
            name = "Tern-0.9.12-linux-x86_64.tar.gz";
            hash = "sha256-9n6MK/9DfzNlrjpHi7wY9jr7blO9bnzVVrrHziTRNpM=";
            message = ''
              Download Tern 0.9.12 from https://build.stencil.so/ and run:
                nix-prefetch-url file://$HOME/Downloads/Tern-0.9.12-linux-x86_64.tar.gz
              Push the imported archive to the lannix Attic cache for CI;
              see modules/hosts/desktops/nixos/nea-desktop/README.md.
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
