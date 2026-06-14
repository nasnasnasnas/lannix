{...}: {
  perSystem = {pkgs, lib, ...}: {
    packages.radaromega = pkgs.appimageTools.wrapType2 {
      pname = "radaromega";
      version = "0.1";
      src = pkgs.fetchurl {
        url = "https://dl.todesktop.com/200402kk4yak2og/linux/appImage/x64";
        hash = "sha256-yPOyu7Vu030cL7gVtNhR4Ag+Bz0H8DiUJXGmFfgouEU=";
      };
      extraInstallCommands = ''
        mkdir -p $out/share/applications
        cat > $out/share/applications/radaromega.desktop << EOF
        [Desktop Entry]
        Type=Application
        Name=RadarOmega
        Exec=$out/bin/radaromega
        Icon=radaromega
        Categories=Utility;
        EOF
      '';
    };
  };
}
