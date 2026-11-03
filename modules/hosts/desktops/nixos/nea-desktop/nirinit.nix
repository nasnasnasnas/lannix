{inputs, ...}: {
  # nirinit saves niri's windows every 5 minutes and reopens them on their
  # workspaces at login (user service on graphical-session.target).
  flake.modules.nixos.nea-desktop = {
    imports = [inputs.nirinit.nixosModules.nirinit];

    services.nirinit = {
      enable = true;
      # These start on their own at login; restoring them would open
      # duplicates. 1Password is spawned by niri.kdl, Hex by its user service,
      # and Noctalia's settings window would launch a second shell.
      settings.skip.apps = ["1password" "anomaly.hex" "dev.noctalia.Noctalia"];
    };
  };
}
