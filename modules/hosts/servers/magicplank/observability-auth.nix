{inputs, ...}: {
  flake.modules.nixos.magicplank = {
    lib,
    pkgs,
    ...
  }: let
    collectors = ["magicbox" "magicplank" "remotebox"];
  in {
    systemd.services.magicplank-caddy = {
      requires = ["opnix-secrets.service"];
      after = ["opnix-secrets.service"];
      serviceConfig.User = "root";
      preStart = ''
        validate_ingestion_account() {
          local collector="$1" account_file="$2"
          if ! ${pkgs.coreutils}/bin/test -r "$account_file" || ! ${pkgs.coreutils}/bin/test -s "$account_file"; then
            echo "Caddy ingestion account for $collector is missing, unreadable or empty: $account_file" >&2
            exit 1
          fi
          if ! LC_ALL=C ${pkgs.gawk}/bin/awk -v collector="$collector" '
            NR != 1 || $0 !~ ("^" collector " [$]2[aby][$]10[$][./A-Za-z0-9]{53}$") { exit 1 }
            END { if (NR != 1) exit 1 }
          ' "$account_file" 2>/dev/null; then
            echo "Caddy ingestion account for $collector has invalid format: $account_file" >&2
            exit 1
          fi
        }
        ${lib.concatMapStringsSep "\n" (collector: let
            accountFile = inputs.self.lib.fileSecretPath "caddy" "/etc/caddy/observability/${collector}.auth";
          in ''
            validate_ingestion_account ${lib.escapeShellArg collector} ${lib.escapeShellArg accountFile}
          '')
          collectors}
      '';
    };
  };
}
