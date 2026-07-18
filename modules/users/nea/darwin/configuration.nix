{inputs, ...}: let
  username = "nea";
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
        inputs.self.modules.homeManager."${username}"
      ];
      home.username = lib.mkForce username;
    };

    users.users."${username}" = {
      name = "Nea Szpunar";
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
