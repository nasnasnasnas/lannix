{ inputs, ... }: {
  flake.modules.homeManager.leah = { pkgs, lib, ... }: {
    imports = with inputs.self.modules.homeManager; [
      default-settings
      leah-shell
      leah-editor
      leah-fetch
      leah-nix-shells
    ];
    home.username = lib.mkDefault "leah";
    home.packages = [ pkgs.htop ];
    programs.fish.enable = true;
    programs.direnv = {
      enable = true;
      enableFishIntegration = true;
    };
    programs.eza = {
      enable = true;
      enableFishIntegration = true;
      icons = "auto";
    };
    programs.git = {
      enable = true;
      settings.user = {
        name = "leah";
        email = "catgirl@catgirlin.space";
      };
    };
  };
}
