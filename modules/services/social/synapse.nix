{ config, ... }: {
  # Synapse merges /config fragments by top-level key, not recursively.
  # Keep secret-bearing blocks entirely in zz-secrets.yaml.
  flake.services.synapse =
    {
      domains ? [ ],
      networks ? [ ],
      dataDir,
      homeserverConfig ? ./synapse/homeserver.yaml,
      logConfig ? ./synapse/szp.lol.log.config,
      secretsFragment,
      signingKeySecret,
      masSharedSecret,
      serverName ? "szp.lol",
      appserviceRegistrations ? { },
      container_name ? "synapse",
      image ? config.flake.lib.image "docker.io/matrixdotorg/synapse",
      restart ? "unless-stopped",
      port ? 8008,
      metricsPort,
      depends_on ? {
        "synapse-db" = {
          condition = "service_healthy";
        };
      },
    }:
    {
      inherit
        domains
        container_name
        image
        restart
        networks
        depends_on
        ;
      caddy_port = port;
      # Keep shared-secret provisioning off the public listener.
      caddyRaw = ''
        ${builtins.concatStringsSep ", " domains} {
            @mas path_regexp ^/_matrix/client/[^/]+/(login|logout|refresh)(/|$)
            handle @mas {
                reverse_proxy matrix-auth:8080
            }
            @private path /_synapse/mas/*
            handle @private {
                respond 404
            }
            handle {
                reverse_proxy ${container_name}:${toString port}
            }
            tls {
                dns cloudflare {env.CF_API_TOKEN}
                resolvers 1.1.1.1
            }
        }
      '';
      environment = {
        SYNAPSE_CONFIG_PATH = "/config";
      };
      fileSecrets = {
        "/config/zz-secrets.yaml" = secretsFragment;
        "/data/${serverName}.signing.key" = signingKeySecret;
        "/run/secrets/mas-shared-secret" = masSharedSecret;
      }
      // appserviceRegistrations;
      ports = if metricsPort != null then ["127.0.0.1:${toString metricsPort}:9000"] else [];
      volumes = [
        "${dataDir}:/data"
        "${homeserverConfig}:/config/homeserver.yaml:ro"
        "${./synapse/mas.yaml}:/config/yy-mas.yaml:ro"
        "${logConfig}:/data/${serverName}.log.config:ro"
      ];
    };
}
