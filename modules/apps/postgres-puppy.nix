{...}: {
  config.flake.lib.mkPostgresPuppy = {pkgs, databases}: let
    databasesJson = builtins.toJSON (map (name: {inherit name;}) databases);
    docker = "${pkgs.docker}/bin/docker";

    script = pkgs.writeText "postgres-puppy.ps1" ''
      $ErrorActionPreference = "Stop"

      $VAULT_ID = "q63632lctm4by3clskcul4gmf4"
      $TAG = "MagicBox Postgres"
      $DOCKER = "${docker}"
      $INPUT = '${databasesJson}' | ConvertFrom-Json

      # Fetch all existing postgres items from 1Password
      $itemList = op item list --vault $VAULT_ID --categories Database --tags $TAG --format json | ConvertFrom-Json
      if (-not $itemList) { $itemList = @() }

      # Build lookup: fetch full details for each existing item
      $allItems = @()
      foreach ($overview in $itemList) {
          $item = op item get $overview.id --vault $VAULT_ID --format json | ConvertFrom-Json
          $allItems += $item
      }

      # Process each requested database
      foreach ($db in $INPUT) {
          $dbName = $db.name

          # Find existing item by database field value
          $existing = $allItems | Where-Object {
              $_.fields | Where-Object { $_.id -eq "database" -and $_.value -eq $dbName }
          } | Select-Object -First 1

          if (-not $existing) {
              Write-Host "Creating 1Password item for $dbName"
              $existing = op item create `
                  --category Database `
                  --vault $VAULT_ID `
                  --tags $TAG `
                  --title "$dbName Postgres" `
                  "--generate-password=20,letters,digits,symbols" `
                  "type=postgresql" `
                  "database=$dbName" `
                  "username=$dbName" `
                  --format json | ConvertFrom-Json
          }

          $password = ($existing.fields | Where-Object { $_.id -eq "password" }).value

          if (-not $password) {
              Write-Host "Adding password to existing item for $dbName"
              op item edit $existing.id --vault $VAULT_ID "--generate-password=20,letters,digits,symbols" | Out-Null
              $updated = op item get $existing.id --vault $VAULT_ID --format json | ConvertFrom-Json
              $password = ($updated.fields | Where-Object { $_.id -eq "password" }).value
          }

          Write-Host "Creating database $dbName if it doesn't exist"

          $sqlTemplate = @'
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = '{0}') THEN
          CREATE USER {0};
        END IF;
      END
      $$;
      ALTER USER {0} WITH PASSWORD '{1}';
      SELECT 'CREATE DATABASE {0} OWNER {0}'
      WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '{0}')\gexec
'@
          $sql = $sqlTemplate -f $dbName, $password
          $sql | & $DOCKER exec -i postgres psql -U postgres
      }

      Write-Host "All Postgres databases updated"
    '';
  in
    pkgs.writeShellApplication {
      name = "postgres-puppy";
      runtimeInputs = [pkgs.powershell pkgs._1password-cli];
      text = ''
        until ${docker} exec postgres pg_isready -U postgres; do
          echo "waiting for postgres..."
          sleep 2
        done

        OP_SERVICE_ACCOUNT_TOKEN=$(cat /etc/op-token)
        export OP_SERVICE_ACCOUNT_TOKEN
        pwsh -File ${script}
      '';
    };
}
