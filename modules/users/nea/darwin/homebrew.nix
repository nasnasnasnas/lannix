{inputs, ...}: let
  username = "nea";
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
      };
    };
  };
}
