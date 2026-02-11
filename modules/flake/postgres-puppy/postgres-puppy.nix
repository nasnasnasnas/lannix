{config, ...}: let
  flakeConfig = config;
in {
  flake.modules.nixos.postgres-puppy = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.puppy-postgres = {
      databases = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "A list of database names to generate.";
      };
    };

    config = lib.mkIf (config.puppy-postgres.databases != []) {
      systemd.services.postgres-puppy = {
        description = "Postgres Puppy database provisioning";
        after = ["docker.service"];
        requires = ["docker.service"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${flakeConfig.flake.lib.mkPostgresPuppy {
            inherit pkgs;
            databases = config.puppy-postgres.databases;
          }}/bin/postgres-puppy";
        };
      };
    };
  };
}
