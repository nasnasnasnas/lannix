{inputs, ...}: {
  flake.modules.nixos.nea-desktop = {
    pkgs,
    lib,
    ...
  }: let
    # Import the downloaded archive and push its fixed-output store path to
    # Attic so CI can substitute it; see README.md.
    tern = inputs.tern.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      version = "0.9.11";
      src = pkgs.requireFile {
        name = "Tern-0.9.11-linux-x86_64.tar.gz";
        hash = "sha256-rWHPGiz4l9/leuC/LmSp6MJSk2DBTc4lGFC+KOdg2+c=";
        message = ''
          Download Tern 0.9.11 from https://build.stencil.so/ and run:
            nix-prefetch-url file://$HOME/Downloads/Tern-0.9.11-linux-x86_64.tar.gz
          Push the imported archive to the lannix Attic cache for CI;
          see modules/hosts/desktops/nixos/nea-desktop/README.md.
        '';
      };
      # Use the account's configured login shell rather than upstream's Nushell probe.
      installPhase =
        builtins.replaceStrings
        ["--set SHELL ${old.passthru.loginShell}/bin/nu"]
        ["--set SHELL ${lib.getExe pkgs.fish}"]
        old.installPhase;
      postFixup =
        (old.postFixup or "")
        + ''
          patchelf --add-rpath "${lib.makeLibraryPath [pkgs.pam pkgs.libpulseaudio]}" "$out/opt/tern/tern"
        '';
    });
  in {
    environment.systemPackages = [
      tern
      (pkgs.makeDesktopItem {
        name = "so.stencil.tern";
        desktopName = "Tern";
        comment = "Stencil native workspace";
        # Upstream ships no icon; macOS27 (icons.nix) provides this name.
        icon = "so.stencil.tern";
        exec = "${lib.getExe tern} %F";
        terminal = false;
        startupWMClass = "so.stencil.tern";
        categories = ["Development" "TerminalEmulator"];
      })
    ];
  };
}
