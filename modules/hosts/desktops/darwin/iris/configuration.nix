{inputs, ...}: {
  flake.modules.darwin.iris = {pkgs, ...}: {
    imports = with inputs.self.modules.darwin; [
      lavender # (adds lavender user + leah's home manager config)
    ];

    environment.systemPackages = with pkgs; [
      git
    ];

    nix.enable = false; # using determinate nix

    # nix-darwin equivalent of NixOS system.stateVersion; don't change after install
    system.stateVersion = 6;
  };
}
