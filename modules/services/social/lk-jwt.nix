{...}: {
  # lk-jwt-service: mints LiveKit JWTs for Matrix RTC. No domain of its own — it is reached
  # by caddy on /sfu/get via the combined matrix-rtc.szp.lol block defined in the livekit
  # service (both sit on the same app network, which caddy joins via caddy.extraNetworks).
  flake.services.lk-jwt = {
    networks ? [],
    livekitUrl,
    fullAccessHomeservers ? "szp.lol",
    envSecrets ? {},
    container_name ? "auth-service",
    image ? "ghcr.io/element-hq/lk-jwt-service:latest",
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
