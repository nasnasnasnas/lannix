{inputs, ...}: {
  flake.modules.darwin.iris = {pkgs, ...}: {
    imports = with inputs.self.modules.darwin; [
      lavender # (adds lavender user + leah's home manager config)
      determinate # using determinate nix; also bridges nix-cache settings into nix.custom.conf
    ];

    environment.systemPackages = with pkgs; [
      git
      ghostty-bin
    ];

    # nix-darwin equivalent of NixOS system.stateVersion; don't change after install
    system.stateVersion = 6;
  };
}
