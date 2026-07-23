{inputs, ...}: let
  username = "lavender";
in {
  flake.modules.darwin."${username}" = {
    pkgs,
    lib,
    ...
  }: {
    homebrew = {
      enable = true;
      enableFishIntegration = true;
      masApps = {
        "1Password for Safari" = 1569813296;
        "Kagi for Safari" = 1622835804;
      };
    };
  };
}
