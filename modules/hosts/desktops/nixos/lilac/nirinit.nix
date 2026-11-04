{ inputs, ... }: {
  # Save niri windows every five minutes and restore their workspaces at login.
  flake.modules.nixos.lilac = {
    imports = [ inputs.nirinit.nixosModules.nirinit ];

    services.nirinit = {
      enable = true;
      # Do not restore 1Password or launch a second Noctalia shell.
      settings.skip.apps = [
        "1password"
        "dev.noctalia.Noctalia"
      ];
    };
  };
}
