{ ... }: {
  flake.modules.nixos.rsync-net-backup =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.backup.rsyncNet;
      secretDir = "/var/lib/opnix/secrets/rsync-net";
      sshKey = "${secretDir}/ssh-key";
      passphrase = "${secretDir}/passphrase";
      pulseUrl = "${secretDir}/pulse-url";
      pulse = pkgs.writeShellScript "rsync-net-borgmatic-pulse" ''
        set -euo pipefail
        url=$(cat ${lib.escapeShellArg pulseUrl})
        if [[ ! "$url" =~ ^https://pulse\.updown\.io/[[:alnum:]_-]+/[[:alnum:]_-]+$ ]]; then
          echo "Invalid updown.io pulse URL for ${config.networking.hostName}" >&2
          exit 1
        fi
        # Supply the secret URL on stdin instead of exposing it in curl's argv.
        printf 'url = "%s"\n' "$url" |
          ${pkgs.curl}/bin/curl --fail --silent --show-error --output /dev/null \
            --max-time 10 --retry 5 --config -
      '';
      sqlitePreflight = pkgs.writeShellScript "rsync-net-sqlite-preflight" (
        lib.concatMapStringsSep "\n" (db: ''
          if [ ! -s ${lib.escapeShellArg db.path} ]; then
            echo "Missing or empty SQLite database: ${db.path}" >&2
            exit 1
          fi
        '') cfg.sqliteDatabases
      );
      settings = {
        source_directories = cfg.sourceDirectories;
        repositories = [
          {
            path = "ssh://fm3250@fm3250.rsync.net/./borg/${config.networking.hostName}";
            label = "rsync-net";
          }
        ];
        source_directories_must_exist = true;
        exclude_patterns = cfg.excludePatterns;
        encryption_passcommand = "${pkgs.coreutils}/bin/cat ${passphrase}";
        ssh_command = "${pkgs.openssh}/bin/ssh -i ${sshKey} -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=yes";
        remote_path = "borg14";
        compression = "auto,zstd,7";
        keep_daily = 7;
        keep_weekly = 4;
        keep_monthly = 6;
        checks = [
          {
            name = "repository";
            frequency = "2 weeks";
          }
          {
            name = "archives";
            frequency = "1 month";
          }
        ];
        check_last = 2;
        retries = 2;
        retry_wait = 30;
      }
      // lib.optionalAttrs (cfg.postgresqlDatabases != [ ]) {
        postgresql_databases = cfg.postgresqlDatabases;
      }
      // lib.optionalAttrs (cfg.sqliteDatabases != [ ]) {
        sqlite_databases = cfg.sqliteDatabases;
        # sqlite3 will silently create a new empty database if one doesn't exist.
        commands = [
          {
            before = "action";
            when = [ "create" ];
            run = [ "${sqlitePreflight}" ];
          }
        ];
      };
    in
    {
      options.backup.rsyncNet = {
        enable = lib.mkEnableOption "borgmatic backups to rsync.net";
        sourceDirectories = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
        excludePatterns = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
        postgresqlDatabases = lib.mkOption {
          type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
          default = [ ];
        };
        sqliteDatabases = lib.mkOption {
          type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
          default = [ ];
        };
        afterServices = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
        pulseSecretReference = lib.mkOption {
          type = lib.types.str;
          description = "1Password reference for this host's updown.io backup pulse URL";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.sourceDirectories != [ ];
            message = "backup.rsyncNet.sourceDirectories must not be empty";
          }
        ];

        programs.ssh.knownHosts."fm3250.rsync.net".publicKey =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINdUkGe6kKn5ssz4WRZKjcws0InbQqZayenzk9obmP1z";

        services.onepassword-secrets.secrets = {
          rsyncNetBackupSshKey = {
            reference = "op://Secrets/rsync.net SSH Key/private key";
            path = sshKey;
            mode = "0600";
          };
          rsyncNetBorgPassphrase = {
            reference = "op://Secrets/rsync.net Borg Passphrase/password";
            path = passphrase;
            mode = "0600";
          };
          rsyncNetBorgPulseUrl = {
            reference = cfg.pulseSecretReference;
            path = pulseUrl;
            mode = "0600";
          };
        };

        services.borgmatic = {
          enable = true;
          inherit settings;
        };

        systemd.services.borgmatic = {
          description = "Back up ${config.networking.hostName} to rsync.net with borgmatic";
          wants = [ "network-online.target" ];
          requires = [ "opnix-secrets.service" ];
          after = [
            "network-online.target"
            "opnix-secrets.service"
          ]
          ++ cfg.afterServices;
          path = [
            pkgs.coreutils
            pkgs.openssh
            pkgs.sudo
            pkgs.docker
            config.services.postgresql.package
          ];
          unitConfig.ConditionACPower = lib.mkForce "";
          serviceConfig = {
            Type = "oneshot";
            RuntimeDirectory = "borgmatic";
            StateDirectory = "borgmatic";
            UMask = "0077";
            LoadCredentialEncrypted = lib.mkForce "";
            NoNewPrivileges = false;
            RestrictSUIDSGID = false;
            CapabilityBoundingSet = "CAP_DAC_READ_SEARCH CAP_NET_RAW CAP_SETUID CAP_SETGID";
            ExecStartPre = lib.mkForce "";
            ExecStart = lib.mkForce "${pkgs.borgmatic}/bin/borgmatic -c /etc/borgmatic/config.yaml create prune compact check";
            ExecStartPost = "${pulse}";
            TimeoutStartSec = "infinity";
          };
        };
        systemd.timers.borgmatic = {
          timerConfig = {
            OnCalendar = lib.mkForce "*-*-* 03:30:00";
            RandomizedDelaySec = "30m";
            Persistent = true;
          };
        };
      };
    };
}
