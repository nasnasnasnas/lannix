{...}: {
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    # Apple publishes these at unversioned URLs; a new release changes the
    # hash, so re-run nix-prefetch-url on the URL and update it here.
    dmgs = {
      SF-Pro = "sha256-loqzuLH5LC2K9h6waA9cIiTE541ZuYa/AEUCp/wBKRg=";
      SF-Mono = "sha256-bUoLeOOqzQb5E/ZCzq0cfbSvNO1IhW1xcaLgtV2aeUU=";
      NY = "sha256-HC7ttFJswPMm+Lfql49aQzdWR2osjFYHJTdgjtuI+PQ=";
    };
  in {
    # San Francisco (SF Pro, SF Pro Text/Display/Rounded, SF Mono) and New
    # York, unpacked from Apple's developer font installers. Apple's license
    # only covers use on Apple platforms.
    packages.apple-fonts = pkgs.stdenvNoCC.mkDerivation {
      pname = "apple-fonts";
      version = "2026-11-02";

      srcs = lib.mapAttrsToList (name: hash:
        pkgs.fetchurl {
          url = "https://devimages-cdn.apple.com/design/resources/download/${name}.dmg";
          inherit hash;
        })
      dmgs;

      nativeBuildInputs = [pkgs._7zz];

      # Each DMG holds a xar .pkg whose Payload is a compressed cpio archive.
      unpackPhase = ''
        runHook preUnpack

        for src in $srcs; do
          work=$(mktemp -d)
          7zz x -y -o"$work/dmg" "$src" >/dev/null
          find "$work/dmg" -type f -name '*.pkg' -print0 |
            while IFS= read -r -d ''' pkg; do
              7zz x -y -o"$work/pkg" "$pkg" >/dev/null
            done
          find "$work/pkg" -type f -name Payload -print0 |
            while IFS= read -r -d ''' payload; do
              dir=$(mktemp -d)
              7zz x -y -o"$dir" "$payload" >/dev/null
              7zz x -y -ofonts "$dir"/Payload~ >/dev/null
            done
        done

        runHook postUnpack
      '';

      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall

        find fonts -type f \( -name '*.otf' -o -name '*.ttf' \) \
          -exec install -Dm444 -t $out/share/fonts/apple {} +

        runHook postInstall
      '';

      meta = {
        description = "Apple's San Francisco and New York fonts";
        homepage = "https://developer.apple.com/fonts/";
        license = lib.licenses.unfree;
        platforms = lib.platforms.all;
      };
    };
  };
}
