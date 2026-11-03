{...}: {
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    accent = import ./_mactahoe-accent.nix;
    # MacTahoe's blues, mapped onto lilac shades of similar lightness.
    hexColors = {
      "#0078F0" = accent.base.hex;
      "#0860F2" = accent.base.hex;
      "#2E73EF" = accent.base.hex;
      "#315BEF" = accent.base.hex;
      "#3484E2" = accent.base.hex;
      "#3776E8" = accent.base.hex;
      "#3D67E3" = accent.base.hex;
      "#31A7E8" = accent.light.hex;
      "#3DAEE9" = accent.light.hex;
      "#5294E2" = accent.light.hex;
      "#5887FC" = accent.light.hex;
      "#597BF2" = accent.light.hex;
      "#A0B4F8" = accent.pale.hex;
      "#1352C4" = accent.dark.hex;
      "#195DDA" = accent.dark.hex;
      "#195EDC" = accent.dark.hex;
      "#3176BF" = accent.dark.hex;
      "#3458C0" = accent.dark.hex;
      "#0852CE" = accent.darker.hex;
    };
    rgbColors = {
      "41,128,185" = accent.base.rgb;
      "49,91,239" = accent.base.rgb;
      "30,146,255" = accent.light.rgb;
      "61,174,230" = accent.light.rgb;
      "61,174,233" = accent.light.rgb;
      "74,124,239" = accent.light.rgb;
      "79,127,239" = accent.light.rgb;
      "83,143,255" = accent.light.rgb;
      "127,160,239" = accent.pale.rgb;
      "128,152,239" = accent.pale.rgb;
      "130,156,239" = accent.pale.rgb;
      "135,163,239" = accent.pale.rgb;
    };
    sedScript = lib.concatStrings (
      lib.mapAttrsToList (from: to: "s/${from}/${to}/Ig;") hexColors
      ++ lib.mapAttrsToList (from: to: "s/=${from}\\b/=${to}/g;") rgbColors
    );
  in {
    # The Qt-facing parts of MacTahoe-kde: the Kvantum theme and the matching
    # KDE color schemes, recolored from blue to the lilac accent in
    # _mactahoe-accent.nix. The Plasma desktop theme, look-and-feel, Aurorae
    # window decorations, and SDDM theme are left out because they only apply
    # inside Plasma, KWin, and SDDM.
    packages.mactahoe-kde = pkgs.stdenvNoCC.mkDerivation {
      pname = "mactahoe-kde";
      version = "0-unstable-2026-08-16";

      src = pkgs.fetchFromGitHub {
        owner = "vinceliuice";
        repo = "MacTahoe-kde";
        rev = "cbf6a1f71b591d143184855d62f6272ce533e7c3";
        hash = "sha256-atdHgr9pCfg/VE8GGWF+4MZu6nRmVCz9TiylVATAwzs=";
      };

      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall

        mkdir -p $out/share
        cp -r Kvantum color-schemes $out/share/
        sed -i '${sedScript}' $out/share/Kvantum/*/* $out/share/color-schemes/*.colors

        runHook postInstall
      '';

      meta = {
        description = "macOS Tahoe like Kvantum theme and KDE color schemes";
        homepage = "https://github.com/vinceliuice/MacTahoe-kde";
        license = lib.licenses.lgpl3Only;
        platforms = lib.platforms.linux;
      };
    };
  };
}
