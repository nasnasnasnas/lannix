{inputs, ...}: {
  # Spotify patched by spicetify. The spiced package replaces pkgs.spotify,
  # which must not be installed alongside it.
  flake.modules.nixos.nea-desktop = {
    config,
    pkgs,
    ...
  }: let
    spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    # Spotify's stylesheets hardcode #ffffffb3, the dark theme's value of
    # --text-subdued, in ~80 rules, mostly on hashed class names. Pointing them
    # back at the token makes them follow the theme. This runs after
    # `spicetify apply` has extracted the stylesheets into $out.
    spotify = config.programs.spicetify.spicedSpotify.overrideAttrs (old: {
      postInstall =
        old.postInstall
        + ''
          sed -i 's/color:#ffffffb3/color:var(--text-subdued)/g' "$out"/share/spotify/Apps/xpui/*.css
        '';
    });
  in {
    imports = [inputs.spicetify-nix.nixosModules.spicetify];

    programs.spicetify = {
      # The module would install the unpatched spicedSpotify; `spotify` above
      # is installed instead.
      enable = false;
      # Light, to match MacTahoe Light. The accent is picked in Spotify's
      # settings page (the theme's JS adds the selector).
      theme = spicePkgs.themes.catppuccin;
      colorScheme = "latte";
      # Recolors the dark overlays and white text Latte leaves behind.
      enabledSnippets = [(builtins.readFile ./spicetify-latte.css)];
    };

    environment.systemPackages = [spotify];
  };
}
