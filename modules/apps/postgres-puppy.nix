{...}: {
  # Server-side, READ-ONLY database provisioner.
  #
  # Passwords are generated off-box and stored in 1Password by the local
  # `nix run .#postgres-puppy-seed` command. This host only needs a read-only
  # 1Password service token: it reads each database's password from 1Password
  # and applies it to Postgres (CREATE USER/DB if missing + ALTER USER PASSWORD).
  config.flake.lib.mkPostgresPuppy = {
    pkgs,
    databases,
  }: let
    databasesJson = builtins.toJSON (map (name: {inherit name;}) databases);
    psql = "${pkgs.postgresql}/bin/psql";
    pg_isready = "${pkgs.postgresql}/bin/pg_isready";
    runuser = "${pkgs.util-linux}/bin/runuser";
  in
    pkgs.writeShellApplication {
      name = "postgres-puppy";
      runtimeInputs = [pkgs._1password-cli pkgs.jq];
      text = ''
        VAULT_ID="q63632lctm4by3clskcul4gmf4"
        TAG="MagicBox Postgres"

        until ${runuser} -u postgres -- ${pg_isready}; do
          echo "waiting for postgres..."
          sleep 2
        done

        OP_SERVICE_ACCOUNT_TOKEN=$(cat /etc/op-token)
        export OP_SERVICE_ACCOUNT_TOKEN
        OP_CONFIG_DIR=$(mktemp -d)
        export OP_CONFIG_DIR

        INPUT=${builtins.toJSON databasesJson}

        # Fetch all existing postgres items from 1Password (read-only)
        ITEM_IDS=$(op item list --vault "$VAULT_ID" --categories Database --tags "$TAG" --format json | jq -r '.[].id')

        # Build lookup: fetch full details for each existing item
        ALL_ITEMS="[]"
        for item_id in $ITEM_IDS; do
          ITEM=$(op item get "$item_id" --vault "$VAULT_ID" --format json)
          ALL_ITEMS=$(echo "$ALL_ITEMS" | jq --argjson item "$ITEM" '. + [$item]')
        done

        # Apply each requested database
        for db_name in $(echo "$INPUT" | jq -r '.[].name'); do
          # Find existing item by database field value
          ITEM=$(echo "$ALL_ITEMS" | jq -r --arg name "$db_name" \
            '[.[] | select(.fields[]? | select(.id == "database" and .value == $name))] | first // empty')

          if [ "$ITEM" = "" ] || [ "$ITEM" = "null" ]; then
            echo "ERROR: no 1Password item found for database '$db_name'." >&2
            echo "This host provisions read-only. Run 'nix run .#postgres-puppy-seed' from a machine" >&2
            echo "with a write-capable 1Password token to generate and store it, then redeploy." >&2
            exit 1
          fi

          PASSWORD=$(echo "$ITEM" | jq -r '.fields[] | select(.id == "password") | .value // empty')
          if [ -z "$PASSWORD" ]; then
            echo "ERROR: 1Password item for database '$db_name' has no password." >&2
            echo "Run 'nix run .#postgres-puppy-seed' to (re)generate it, then redeploy." >&2
            exit 1
          fi

          echo "Applying database $db_name"

          # Double single quotes so arbitrary generated passwords are safe as a SQL literal.
          PW_SQL=''${PASSWORD//\'/\'\'}

          SQL=$(cat <<EOSQL
        DO \$\$
        BEGIN
          IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = '$db_name') THEN
            CREATE USER $db_name;
          END IF;
        END
        \$\$;
        ALTER USER $db_name WITH PASSWORD '$PW_SQL';
        SELECT 'CREATE DATABASE $db_name OWNER $db_name'
        WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$db_name')\gexec
        EOSQL
          )

          echo "$SQL" | ${runuser} -u postgres -- ${psql}
        done

        echo "All Postgres databases applied"
      '';
    };
}
