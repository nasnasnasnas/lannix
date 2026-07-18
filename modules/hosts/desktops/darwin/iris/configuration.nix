{inputs, ...}: {
  flake.modules.darwin.iris = {pkgs, ...}: {
    imports = with inputs.self.modules.darwin; [
      lavender # (adds lavender user + leah's home manager config)
      determinate # using determinate nix; also bridges nix-cache settings into nix.custom.conf
      nea
    ];

    environment.systemPackages = with pkgs; [
      git
      ghostty-bin
    ];

    system.primaryUser = "lavender";
    users.users.nea = {
      uid = 502;
    };
    users.knownUsers = ["nea"];

    # nix-darwin equivalent of NixOS system.stateVersion; don't change after install
    system.stateVersion = 6;
  };
}
