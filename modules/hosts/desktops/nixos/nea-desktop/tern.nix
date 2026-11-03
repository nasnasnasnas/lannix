{inputs, ...}: {
  flake.modules.nixos.nea-desktop = {
    pkgs,
    lib,
    ...
  }: let
    # Import the private beta once with:
    # nix-prefetch-url file://$HOME/Downloads/Tern-0.9.8-linux-x86_64.tar.gz
    tern = inputs.tern.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      version = "0.9.8";
      src = pkgs.requireFile {
        name = "Tern-0.9.8-linux-x86_64.tar.gz";
        hash = "sha256-TCCTx1UXTmAtT4bJeB5UOhVkrxrvI/NCFSLUNs9goFQ=";
        message = "Download Tern 0.9.8 from https://build.stencil.so/ and run nix-prefetch-url file://$HOME/Downloads/Tern-0.9.8-linux-x86_64.tar.gz";
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
