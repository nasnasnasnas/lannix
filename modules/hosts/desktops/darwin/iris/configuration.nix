{inputs, ...}: {
  flake.modules.darwin.iris = {
    imports = with inputs.self.modules.darwin; [
      lavender # (adds lavender user + leah's home manager config)
    ];

    # nix-darwin equivalent of NixOS system.stateVersion; don't change after install
    system.stateVersion = 6;
  };
}
