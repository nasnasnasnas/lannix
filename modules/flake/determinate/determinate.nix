{inputs, ...}: {
  # For hosts running Determinate Nix: determinate-nixd owns /etc/nix/nix.conf,
  # so nix-darwin's nix.settings is inert (the determinate module force-disables
  # nix.enable). Mirror the cache settings from nix.settings (set by the
  # nix-cache module) into determinate's /etc/nix/nix.custom.conf instead.
  flake.modules.darwin.determinate = {config, ...}: {
    imports = [inputs.determinate.darwinModules.default];

    determinateNix.customSettings = {
      extra-substituters = config.nix.settings.extra-substituters or [];
      extra-trusted-public-keys = config.nix.settings.extra-trusted-public-keys or [];
    };
  };
}
