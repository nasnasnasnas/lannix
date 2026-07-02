{inputs, ...}: {
  # perSystem's default `pkgs` comes straight from nixpkgs.legacyPackages with no config,
  # so unfree perSystem packages (postgres-puppy-seed -> 1password-cli, pulumi-dns-gen ->
  # pulumi-bin) fail to evaluate. Mirror the allowUnfree that nixos/home-manager already set.
  perSystem = {system, ...}: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  };
}
