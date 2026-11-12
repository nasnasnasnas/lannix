# Native Polyphony package for Leah's Linux profile; no Flatpak runtime required.
# Playback requires a paid Apple Music subscription. Keep the orchestrator pin in
# polyphony/_orchestrator.nix aligned with upstream's python3-orchestrator.json.
{ ... }: {
  perSystem = { pkgs, lib, ... }: {
    packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      polyphony =
        let
          python = pkgs.python3;
          orchestrator = pkgs.callPackage ./polyphony/_orchestrator.nix { };
          discord-rpc = python.pkgs.buildPythonPackage {
            pname = "discord-rpc";
            version = "0-unstable-43beada";
            pyproject = true;
            src = pkgs.fetchFromGitHub {
              owner = "Senophyx";
              repo = "Discord-RPC";
              rev = "43beada1f1cc0c7cd2c4c2f53ab0672133a86dea";
              hash = "sha256-8wHZ7ydXPGtH3Wyf9w+7d9bQ31Llr9v6rm8Ngw9qqak=";
            };
            build-system = [ python.pkgs.setuptools ];
            pythonImportsCheck = [ "discordrpc" ];
          };
        in
        pkgs.stdenv.mkDerivation {
          pname = "polyphony";
          version = "1-unstable-2026-11-11";
          src = pkgs.fetchgit {
            url = "https://gitlab.gnome.org/jannuary/polyphony.git";
            rev = "c84db8633b0eec40ec9ff109ecfab2b530b78c86";
            hash = "sha256-yX7IB2pvX0Ll0bZRA7jDagO42yVGT6exURMXxS4wo1g=";
          };
          # XDG_DATA_HOME is optional outside Flatpak; GLib supplies its default.
          postPatch = ''
            substituteInPlace src/main.py \
              --replace-fail "Path(os.getenv('XDG_DATA_HOME'))" \
                "Path(GLib.get_user_data_dir())"
          '';

          nativeBuildInputs = with pkgs; [
            meson
            ninja
            pkg-config
            gettext
            blueprint-compiler
            desktop-file-utils
            wrapGAppsHook4
            gobject-introspection
          ];
          buildInputs = with pkgs; [
            gtk4
            libadwaita
            webkitgtk_6_0
            libsecret
            libsoup_3
            libglycin
            libglycin-gtk4
            # Glycin's setup hook adds decoder configs to the app's XDG_DATA_DIRS.
            glycin-loaders
            glib-networking
            gst_all_1.gstreamer
            gst_all_1.gst-plugins-base
            gst_all_1.gst-plugins-good
            gst_all_1.gst-plugins-bad
            gst_all_1.gst-libav
            (python.withPackages (ps: [
              ps.pygobject3
              ps.pylast
              discord-rpc
              orchestrator
            ]))
          ];
          preFixup = ''
            gappsWrapperArgs+=(
              --set POLYPHONY_ORCHESTRATOR_ASSETS "${orchestrator}/share/orchestrator"
            )
          '';

          meta = {
            description = "GNOME Apple Music player";
            homepage = "https://gitlab.gnome.org/jannuary/polyphony";
            license = lib.licenses.gpl3Plus;
            mainProgram = "polyphony";
            platforms = [
              "x86_64-linux"
              "aarch64-linux"
            ];
          };
        };
    };
  };
}
