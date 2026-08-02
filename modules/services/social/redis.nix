{config, ...}: {
  # Generic Redis container (used by Sharkey).
  flake.services.redis = {
    dataDir,
    container_name ? "redis",
    networks ? [],
    image ? config.flake.lib.image "redis",
    restart ? "always",
  }: {
    inherit container_name image restart networks;
    volumes = ["${dataDir}:/data"];
    healthcheck = {
      test = ["CMD" "redis-cli" "ping"];
      interval = "10s";
      timeout = "3s";
      retries = 5;
      start_period = "10s";
    };
  };
}
