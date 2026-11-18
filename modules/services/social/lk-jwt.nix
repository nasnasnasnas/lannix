{ config, ... }: {
  # MatrixRTC authorization application service. Synapse proxies the C-S/S-S APIs to
  # this service; Caddy exposes the legacy endpoints and LiveKit's signed webhook.
  # Both containers read the same opnix-managed application-service registration.
  flake.services.lk-jwt =
    {
      networks ? [ ],
      livekitUrl,
      serverName,
      registrationSecret,
      envSecrets ? { },
      container_name ? "auth-service",
      image ? config.flake.lib.image "ghcr.io/element-hq/lk-jwt-service",
      restart ? "unless-stopped",
      port ? 8080,
    }:
    {
      inherit
        container_name
        image
        restart
        networks
        envSecrets
        ;
      environment = {
        LIVEKIT_JWT_BIND = ":${toString port}";
        LIVEKIT_URL = livekitUrl;
        # Retained for old clients; a single matching homeserver enables membership checks.
        LIVEKIT_FULL_ACCESS_HOMESERVERS = serverName;
        LIVEKIT_HS_SERVER_NAME = serverName;
        LIVEKIT_AS_REGISTRATION_FILE = "/etc/lk-jwt/registration.yaml";
      };
      fileSecrets = {
        "/etc/lk-jwt/registration.yaml" = registrationSecret;
      };
    };
}
