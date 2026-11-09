{ inputs, ... }: {
  # Save niri windows every five minutes and restore their workspaces at login.
  flake.modules.nixos.lilac-nirinit = {
    imports = [ inputs.nirinit.nixosModules.nirinit ];

    services.nirinit = {
      enable = true;
      # Do not restore 1Password or launch a second Noctalia shell.
      settings.skip.apps = [
        "1password"
        "dev.noctalia.Noctalia"
      ];
    };

    # graphical-session.target also starts under Umbriel, which has no Niri IPC.
    systemd.user.services.nirinit.unitConfig.ConditionEnvironment = "XDG_CURRENT_DESKTOP=niri";
  };
}
