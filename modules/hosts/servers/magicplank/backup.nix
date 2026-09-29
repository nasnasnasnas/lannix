{inputs, ...}: {
  flake.modules.nixos.magicplank = {pkgs, ...}: {
    imports = [inputs.self.modules.nixos.rsync-net-backup];

    backup.rsyncNet = {
      enable = true;
      pulseSecretReference = "op://Secrets/updown.io pulse endpoints for backups/MagicPlank";
      sourceDirectories = [
        "/home/magicbox/data"
        "/home/magicbox/smb"
      ];
      excludePatterns = [
        # Metrics, logs, and profiles are disposable and could exceed the shared quota.
        "/home/magicbox/data/grafana/plugins"
        "/home/magicbox/data/grafana/grafana.db*"
        "/home/magicbox/data/pyroscope"
        "/home/magicbox/data/victorialogs"
        "/home/magicbox/data/victoriametrics"
        # Consistent logical dumps below replace these live PostgreSQL files.
        "/home/magicbox/data/synapse-db"
        "/home/magicbox/data/sharkey-db"
        "/home/magicbox/data/sharkey-redis"
        "/home/magicbox/data/attic/server.db*"
        "/home/magicbox/data/attic/storage"
      ];
      afterServices = ["postgresql.service" "docker.service"];
      sqliteDatabases = [
        {name = "attic-server"; path = "/home/magicbox/data/attic/server.db";}
        {name = "grafana"; path = "/home/magicbox/data/grafana/grafana.db";}
      ];
      postgresqlDatabases = [
        {
          name = "all";
          username = "postgres";
        }
        {
          name = "synapse";
          label = "synapse-db";
          username = "synapse";
          pg_dump_command = "${pkgs.docker}/bin/docker exec -u postgres synapse-db pg_dump";
          pg_restore_command = "${pkgs.docker}/bin/docker exec -i -u postgres synapse-db pg_restore";
          psql_command = "${pkgs.docker}/bin/docker exec -i -u postgres synapse-db psql";
        }
        {
          name = "misskey";
          label = "sharkey-db";
          username = "example-misskey-user";
          pg_dump_command = "${pkgs.docker}/bin/docker exec -u postgres sharkey-db pg_dump";
          pg_restore_command = "${pkgs.docker}/bin/docker exec -i -u postgres sharkey-db pg_restore";
          psql_command = "${pkgs.docker}/bin/docker exec -i -u postgres sharkey-db psql";
        }
      ];
    };
  };
}
