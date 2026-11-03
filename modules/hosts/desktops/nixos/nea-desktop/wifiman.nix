{...}: {
  flake.modules.nixos.nea-desktop = {pkgs, ...}: let
    payload = pkgs.stdenvNoCC.mkDerivation rec {
      pname = "wifiman-desktop";
      version = "1.2.7";
      src = pkgs.fetchurl {
        url = "https://desktop.ea.wifiman.com/wifiman-desktop-${version}-amd64.deb";
        hash = "sha256-aHGtifGEyNfA/ixDoxzifyVJBmbxdogTlhxR5uuoZNQ=";
      };
      nativeBuildInputs = [pkgs.dpkg];
      unpackPhase = "true";
      installPhase = ''
        mkdir -p $out
        dpkg -x $src $out
        cp -a $out/usr/. $out/
        rm -rf $out/usr
      '';
    };
    launcher = pkgs.writeShellScript "wifiman-launcher" ''
      daemon="${payload}/lib/wifiman-desktop/wifiman-desktopd"
      if [ -x "$daemon" ] && ! ${pkgs.procps}/bin/pgrep -f "$daemon" >/dev/null; then
        "$daemon" &
      fi
      exec "${payload}/bin/wifiman-desktop" "$@"
    '';
  in {
    environment.systemPackages = [
      (pkgs.buildFHSEnv {
        name = "wifiman";
        targetPkgs = p:
          with p; [
            glib
            openssl
            webkitgtk_4_1
            gtk3
            gcc-unwrapped
            pango
            gdk-pixbuf
            cairo
            libsoup_3
            xdg-utils
            desktop-file-utils
            libayatana-appindicator
            libdbusmenu-gtk3
            wirelesstools
            iw
          ];
        runScript = launcher;
      })
    ];
  };
}
