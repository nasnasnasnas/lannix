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
      services.postgresql = {
        enable = true;
        enableTCPIP = true;
        authentication = lib.mkAfter ''
          host all all 172.16.0.0/12 md5
        '';
      };

      networking.firewall.extraCommands = ''
        iptables -I nixos-fw -p tcp -s 172.16.0.0/12 --dport 5432 -j nixos-fw-accept
      '';
      networking.firewall.extraStopCommands = ''
        iptables -D nixos-fw -p tcp -s 172.16.0.0/12 --dport 5432 -j nixos-fw-accept || true
      '';

      systemd.services.postgres-puppy = {
        description = "Postgres Puppy database provisioning";
        after = ["postgresql.service"];
        requires = ["postgresql.service"];
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
