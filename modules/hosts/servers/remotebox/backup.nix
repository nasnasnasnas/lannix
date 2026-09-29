{inputs, ...}: {
  flake.modules.nixos.remotebox = {...}: {
    imports = [inputs.self.modules.nixos.rsync-net-backup];

    backup.rsyncNet = {
      enable = true;
      pulseSecretReference = "op://Secrets/updown.io pulse endpoints for backups/RemoteBox";
      sourceDirectories = ["/home/magicbox/data"];
      excludePatterns = [
        "/home/magicbox/data/wokecraft/logs"
        "/home/magicbox/data/picturesplace/data.db*"
        "/home/magicbox/data/picturesplace/queue.db*"
        "/home/magicbox/data/ntfy/auth.db*"
        "/home/magicbox/data/ntfy/cache.db*"
        "/home/magicbox/data/pocket-id/pocket-id.db*"
      ];
      afterServices = ["postgresql.service"];
      sqliteDatabases = [
        {name = "picturesplace-data"; path = "/home/magicbox/data/picturesplace/data.db";}
        {name = "picturesplace-queue"; path = "/home/magicbox/data/picturesplace/queue.db";}
        {name = "ntfy-auth"; path = "/home/magicbox/data/ntfy/auth.db";}
        {name = "ntfy-cache"; path = "/home/magicbox/data/ntfy/cache.db";}
        {name = "pocket-id"; path = "/home/magicbox/data/pocket-id/pocket-id.db";}
      ];
      postgresqlDatabases = [
        {
          name = "all";
          username = "postgres";
        }
      ];
    };
  };
}
