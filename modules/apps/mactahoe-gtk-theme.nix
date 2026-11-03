{...}: {
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    accent = import ./_mactahoe-accent.nix;
  in {
    # macOS Tahoe GTK 2/3/4 theme, built from source with translucent
    # ("normal") surfaces and the lilac accent from _mactahoe-accent.nix.
    # MacTahoe's "purple" variant carries the accent so its prebuilt purple
    # slider assets are used; its palette color is replaced with the lilac.
    packages.mactahoe-gtk-theme = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
      pname = "mactahoe-gtk-theme";
      version = "2026-09-10";

      src = pkgs.fetchFromGitHub {
        owner = "vinceliuice";
        repo = "MacTahoe-gtk-theme";
        tag = finalAttrs.version;
        hash = "sha256-P4zevOTHd7KKLj3a9wkaY96tMFMg7iZEpz3NkbdyTwM=";
      };

      strictDeps = true;

      nativeBuildInputs = with pkgs; [
        dialog
        glib
        jdupes
        libxml2
        sassc
        util-linux
      ];

      postPatch = ''
        find -name "*.sh" -print0 | while IFS= read -r -d ''' file; do
          patchShebangs "$file"
        done

        # The install script only needs sudo and the user's home for
        # system-wide or ~/.themes installs; neither applies to $out.
        substituteInPlace libs/lib-core.sh \
          --replace-fail 'SUDO_BIN="$(command -v sudo)"' 'SUDO_BIN=false' \
          --replace-fail 'MY_HOME=$(getent passwd "''${MY_USERNAME}" | cut -d: -f6)' 'MY_HOME=/tmp'

        # Skip the bundled GNOME theme switcher; it installs into ~/.local.
        substituteInPlace install.sh --replace-fail '  install_app' '  true'

        substituteInPlace src/sass/_colors-palette.scss \
          --replace-fail '$theme_color_purple:  #9A57A3;' '$theme_color_purple:  ${accent.base.hex};'
        # Default ("suggested") buttons use the accent, as on macOS, instead
        # of always being blue.
        substituteInPlace src/sass/_colors.scss \
          --replace-fail '$suggested_color:                   if($scheme == '"'"'nord'"'"', $nord_color_blue, $theme_color_blue);' \
            '$suggested_color:                   $selected_bg_color;'
      '';

      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall

        mkdir -p $out/share/themes
        ./install.sh \
          --color light --color dark \
          --opacity normal \
          --theme purple \
          --dest $out/share/themes

        jdupes --quiet --link-soft --recurse $out/share

        runHook postInstall
      '';

      meta = {
        description = "macOS Tahoe like theme for GTK 3, GTK 4 and libadwaita";
        homepage = "https://github.com/vinceliuice/MacTahoe-gtk-theme";
        license = lib.licenses.mit;
        platforms = lib.platforms.linux;
      };
    });
  };
}
