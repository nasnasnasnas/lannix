{...}: {
  # Generic Redis container (used by Sharkey).
  flake.services.redis = {
    dataDir,
    container_name ? "redis",
    networks ? [],
    image ? "redis:7-alpine",
    restart ? "always",
  }: {
    inherit container_name image restart networks;
    volumes = ["${dataDir}:/data"];
  };
}
