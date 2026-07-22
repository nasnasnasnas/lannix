{inputs, ...}: let
  username = "lavender";
in {
  flake.modules.darwin."${username}" = {
    pkgs,
    lib,
    ...
  }: {
    imports = with inputs.self.modules.darwin; [
      home-manager
    ];

    home-manager.users."${username}" = {
      imports = [
        # leah's cross-platform home manager config
        # (linux-only bits live in homeManager.leah-linux and are not imported here)
        inputs.self.modules.homeManager.leah
        inputs.self.modules.homeManager.leah-darwin
      ];
      # the account on this mac is "lavender", not "leah"
      home.username = lib.mkForce username;
    };

    users.users."${username}" = {
      description = "Lavender System";
      home = "/Users/${username}";
      shell = pkgs.fish;
    };

    programs.fish.enable = true;

    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      nerd-fonts.jetbrains-mono
    ];
  };
}
