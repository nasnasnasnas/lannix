{ config, ... }: {
  flake.services.matrix-auth =
    {
      domains ? [ ],
      networks ? [ ],
      configSecret,
      databasePasswordSecret,
      sharedSecret,
      image ? config.flake.lib.image "ghcr.io/element-hq/matrix-authentication-service",
    }:
    {
      container_name = "matrix-auth";
      inherit image networks domains;
      restart = "unless-stopped";
      caddy_port = 8080;
      environment.MAS_CONFIG = "/etc/mas/config.yaml:/etc/mas/secrets.yaml";
      command = [ "server" ];
      depends_on.mas-db.condition = "service_healthy";
      fileSecrets = {
        "/etc/mas/secrets.yaml" = configSecret;
        "/run/secrets/database-password" = databasePasswordSecret;
        "/run/secrets/matrix-secret" = sharedSecret;
      };
      volumes = [
        "${./matrix-auth/config.yaml}:/etc/mas/config.yaml:ro"
      ];
    };
}
