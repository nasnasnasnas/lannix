{config, ...}: {
  # lk-jwt-service: mints LiveKit JWTs for Matrix RTC. No domain of its own — it is reached
  # by caddy on /sfu/get via the combined matrix-rtc.szp.lol block defined in the livekit
  # service (it is attached to the host proxy network via caddyExtraBackends).
  flake.services.lk-jwt = {
    networks ? [],
    livekitUrl,
    fullAccessHomeservers ? "szp.lol",
    envSecrets ? {},
    container_name ? "auth-service",
    image ? config.flake.lib.image "ghcr.io/element-hq/lk-jwt-service",
    restart ? "unless-stopped",
    port ? 8080,
  }: {
    inherit container_name image restart networks envSecrets;
    environment = {
      LIVEKIT_JWT_PORT = toString port;
      LIVEKIT_URL = livekitUrl;
      LIVEKIT_FULL_ACCESS_HOMESERVERS = fullAccessHomeservers;
    };
  };
}
