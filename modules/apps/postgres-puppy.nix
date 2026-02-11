{...}: {
  config.flake.lib.mkPostgresPuppy = {pkgs, databases}: let
    postgresPuppyScript = ./postgres-puppy/index.ts;
    databasesJson = builtins.toJSON (map (name: {inherit name;}) databases);
  in
    pkgs.writeShellApplication {
      name = "postgres-puppy";
      runtimeInputs = [pkgs.bun];
      text = ''
        # set the OP_SERVICE_ACCOUNT_TOKEN env to contents of /etc/op-token
        OP_SERVICE_ACCOUNT_TOKEN=$(cat /etc/op-token)
        export OP_SERVICE_ACCOUNT_TOKEN
        bun i @1password/sdk
        bun run ${postgresPuppyScript} ${builtins.toJSON databasesJson} ${pkgs.docker}/bin/docker'';
    };
}
