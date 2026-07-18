{inputs, ...}: let
  username = "nea";
in {
  flake.modules.homeManager."${username}" = {pkgs, ...}: {
    imports = with inputs.self.modules.homeManager; [
      default-settings
    ];
    home.username = "${username}";
    home.packages = with pkgs; [
      htop
    ];

    programs.fish.enable = true;
    programs.git = {
      enable = true;
      signing = {
        key = ""; # TODO
        format = "ssh";
        signByDefault = true;
        signer =
          if pkgs.stdenv.isDarwin
          then "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
          else "/run/current-system/sw/bin/op-ssh-sign";
      };
      settings.user = {
        name = "nea";
        email = "git@nea.dev";
      };
    };
  };
}
