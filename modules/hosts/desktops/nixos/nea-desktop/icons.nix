{...}: {
  flake.modules.homeManager.nea-desktop = {
    config,
    lib,
    pkgs,
    ...
  }: let
    # Import the downloaded archive and push its fixed-output store path to
    # Attic so CI can substitute it; see README.md.
    macos27-icon-theme = pkgs.stdenvNoCC.mkDerivation {
      pname = "macos27-icon-theme";
      version = "2026-11-02";

      src = pkgs.requireFile {
        name = "macOS27.tar.gz";
        hash = "sha256-oYdLADXQSwvuutRU1wVtEcthtR5lvuawmzSW6KOSeg0=";
        message = ''
          Import the icon archive with:
            nix-prefetch-url file://$HOME/Downloads/macOS27.tar.gz
          Push the imported archive to the lannix Attic cache for CI;
          see modules/hosts/desktops/nixos/nea-desktop/README.md.
        '';
      };
      # The archive also carries macOS27-Dark; only the light theme is used.
      sourceRoot = "macOS27";

      # gtk-update-icon-cache; ~27k entries make an uncached lookup slow, so
      # keep the cache gtk3's setup hook would otherwise drop.
      nativeBuildInputs = [pkgs.gtk3];
      dontDropIconThemeCache = true;

      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall

        mkdir -p $out/share/icons
        cp -a . $out/share/icons/macOS27
        gtk-update-icon-cache $out/share/icons/macOS27

        runHook postInstall
      '';
    };
  in {
    gtk.iconTheme = {
      name = "macOS27";
      package = macos27-icon-theme;
    };
    # macOS27 only covers app, place, device, and MIME icons and inherits the
    # rest (toolbar actions, status, symbolic icons) from Adwaita.
    home.packages = [pkgs.adwaita-icon-theme];
    # KDE apps read the icon theme from kdeglobals rather than GSettings.
    home.activation.kdeglobalsIconTheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
        --file "${config.xdg.configHome}/kdeglobals" \
        --group Icons --key Theme -- ${config.gtk.iconTheme.name}
    '';
  };
}
