{...}: {
  flake.modules.nixos.nea-desktop = {pkgs, ...}: {
    # Niri does not expose the overview swipe direction as a setting.
    # Reverse only its four-finger gesture, independently of natural scrolling.
    programs.niri.package = pkgs.niri.overrideAttrs (old: {
      patches = (old.patches or []) ++ [./reverse-overview-swipe.patch];
      env =
        (old.env or {})
        // {
          NIRI_BUILD_COMMIT = "Nixpkgs-four-finger-reversed";
        };
    });
  };
}
