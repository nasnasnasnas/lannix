{ inputs, ... }:
let
  username = "lavender";
in
{
  flake.modules.darwin."${username}" =
    {
      pkgs,
      lib,
      ...
    }:
    {
      imports = with inputs.self.modules.darwin; [
        home-manager
      ];

      home-manager.users."${username}" = {
        imports = [
          inputs.self.modules.homeManager.leah
          inputs.self.modules.homeManager.leah-tools-darwin
          inputs.self.modules.homeManager.leah-desktop-darwin
        ];
        # the account on this mac is "lavender", not "leah"
        home.username = username;
      };

      users.users."${username}" = {
        description = "Lavender System";
        home = "/Users/${username}";
        shell = pkgs.fish;
      };

      programs.fish.enable = true;
      services.tailscale.enable = true;

      fonts.packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        liberation_ttf
        nerd-fonts.jetbrains-mono
      ];
    };
}
