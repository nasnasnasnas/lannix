{
  config,
  lib,
  ...
}: {
  # Local, WRITE-side counterpart to the server `postgres-puppy` provisioner.
  #
  # Run from a machine whose own `op` CLI can WRITE to 1Password (desktop-app integration
  # or a write-capable OP_SERVICE_ACCOUNT_TOKEN). It deliberately uses the `op` already on
  # your PATH rather than a pinned nixpkgs build, because 1Password's desktop integration
  # only trusts the system-installed CLI. It generates a password for every Postgres
  # database declared across all nixosConfigurations and stores it as a Database item in
  # the shared vault. Deployed hosts then read those items read-only via postgres-puppy.
  #
  #   nix run .#postgres-puppy-seed
  perSystem = {pkgs, ...}: let
    allDatabases = lib.unique (lib.concatMap
      (cfg: cfg.config.postgres-puppy.databases or [])
      (lib.attrValues config.flake.nixosConfigurations));
    databasesJson = builtins.toJSON (map (name: {inherit name;}) allDatabases);
  in {
    packages.postgres-puppy-seed = pkgs.writeShellApplication {
      name = "postgres-puppy-seed";
      # `op` intentionally omitted: use the caller's PATH `op` for desktop-app integration.
      runtimeInputs = [pkgs.jq pkgs.openssl];
      text = ''
        VAULT_ID="q63632lctm4by3clskcul4gmf4"
        TAG="MagicBox Postgres"

        if ! command -v op >/dev/null 2>&1; then
          echo "ERROR: 1Password CLI ('op') not found on PATH." >&2
          echo "Install it and sign in so that 'op vault list' works, then re-run." >&2
          exit 1
        fi

        INPUT=${builtins.toJSON databasesJson}

        NAMES=$(echo "$INPUT" | jq -r '.[].name')
        if [ -z "$NAMES" ]; then
          echo "No databases declared across nixosConfigurations; nothing to seed."
          exit 0
        fi

        # Fetch all existing postgres items once
        ITEM_IDS=$(op item list --vault "$VAULT_ID" --categories Database --tags "$TAG" --format json | jq -r '.[].id')
        ALL_ITEMS="[]"
        for item_id in $ITEM_IDS; do
          ITEM=$(op item get "$item_id" --vault "$VAULT_ID" --format json)
          ALL_ITEMS=$(echo "$ALL_ITEMS" | jq --argjson item "$ITEM" '. + [$item]')
        done

        for db_name in $NAMES; do
          ITEM=$(echo "$ALL_ITEMS" | jq -r --arg name "$db_name" \
            '[.[] | select(.fields[]? | select(.id == "database" and .value == $name))] | first // empty')

          if [ "$ITEM" = "" ] || [ "$ITEM" = "null" ]; then
            echo "Creating 1Password item for $db_name"
            GEN_PASS=$(openssl rand -base64 20)
            op item create \
              --category Database \
              --vault "$VAULT_ID" \
              --tags "$TAG" \
              --title "''${db_name} Postgres" \
              "type=postgresql" \
              "password=$GEN_PASS" \
              "database=$db_name" \
              "username=$db_name" > /dev/null
            continue
          fi

          PASSWORD=$(echo "$ITEM" | jq -r '.fields[] | select(.id == "password") | .value // empty')
          if [ -z "$PASSWORD" ]; then
            echo "Adding password to existing item for $db_name"
            ITEM_ID=$(echo "$ITEM" | jq -r '.id')
            GEN_PASS=$(openssl rand -base64 20)
            op item edit "$ITEM_ID" --vault "$VAULT_ID" "password=$GEN_PASS" > /dev/null
          else
            echo "$db_name already provisioned; skipping"
          fi
        done

        echo "Seeding complete"
      '';
    };
  };
}
