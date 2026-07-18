{
  inputs,
  self,
  ...
}: let
  username = "nea";
in {
  flake.modules.nixos."${username}" = {
    lib,
    config,
    pkgs,
    ...
  }: {
    imports = with inputs.self.modules.nixos; [
      # nixos modules for leneaah
    ];

    home-manager.users."${username}" = {
      imports = [
        # home manager modules for nea (including home.nix right next to us)
        inputs.self.modules.homeManager."${username}"
        # inputs.self.modules.homeManager."${username}-linux"
      ];
    };

    users.users."${username}" = {
      isNormalUser = true;
      shell = pkgs.fish;
      extraGroups = ["docker"];
    };
    programs.fish.enable = true;

    fonts.enableDefaultPackages = true;
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      nerd-fonts.jetbrains-mono
    ];
  };
}
