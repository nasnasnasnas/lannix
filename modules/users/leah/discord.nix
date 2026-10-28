{
  inputs,
  self,
  ...
}: let
  username = "leah";
in {
  flake.modules.nixos."${username}" = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      unstable.vesktop
      (unstable.discord.override {
        # withOpenASAR = true; # complementary
        withVencord = true;
      })
    ];
  };

  flake.modules.homeManager."${username}-linux" = {pkgs, ...}: {
    services.arrpc = {
      enable = true;
      package = pkgs.arrpc; # Default
      systemdTarget = "graphical-session.target"; # default
    };
  };
}