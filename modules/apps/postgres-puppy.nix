{...}: {
  config.flake.lib.mkPostgresPuppy = {pkgs, databases}: let
    postgresPuppyScript = ./postgres-puppy/index.ts;
    databasesJson = builtins.toJSON (map (name: {inherit name;}) databases);
    docker = "${pkgs.docker}/bin/docker";
  in
    pkgs.writeShellApplication {
      name = "postgres-puppy";
      runtimeInputs = [pkgs.bun];
      text = ''
        until ${docker} exec postgres pg_isready -U postgres; do
          echo "waiting for postgres..."
          sleep 2
        done

        # set the OP_SERVICE_ACCOUNT_TOKEN env to contents of /etc/op-token
        OP_SERVICE_ACCOUNT_TOKEN=$(cat /etc/op-token)
        export OP_SERVICE_ACCOUNT_TOKEN
        bun i @1password/sdk
        bun run ${postgresPuppyScript} ${builtins.toJSON databasesJson} ${docker}'';
    };
}
