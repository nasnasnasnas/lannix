{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    packages.noctalia-config-sync = pkgs.writeShellApplication {
      name = "noctalia-config-sync";
      runtimeInputs = [
        inputs.noctalia.packages.${system}.default
        pkgs.alejandra
        pkgs.bun
        pkgs.git
        pkgs.nix
        pkgs.nixos-rebuild
      ];
      text = ''
        export NOCTALIA_CONFIG_SYNC_NIXPKGS="${pkgs.path}"
        exec bun ${./noctalia-config-sync.ts} "$@"
      '';
    };
  };
}
