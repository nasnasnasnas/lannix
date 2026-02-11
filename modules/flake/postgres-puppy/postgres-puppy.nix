{config, ...}: let
  flakeConfig = config;
in {
  flake.modules.nixos.postgres-puppy = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.postgres-puppy = {
      databases = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "A list of database names to generate.";
      };
    };

    config = lib.mkIf (config.postgres-puppy.databases != []) {
      systemd.services.postgres-puppy = {
        description = "Postgres Puppy database provisioning";
        after = ["docker.service"];
        requires = ["docker.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${flakeConfig.flake.lib.mkPostgresPuppy {
            inherit pkgs;
            databases = config.postgres-puppy.databases;
          }}/bin/postgres-puppy";
        };
      };
    };
  };
}
