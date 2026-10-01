{config, ...}: {
  flake.services.immich = {
    domains ? [],
    networks ? [],
    image ? config.flake.lib.image "ghcr.io/immich-app/immich-server",
    dataDir,
    dbPasswordSecret,
    dbHost ? "immich-db",
    dbName ? "immich",
    dbUser ? "immich",
    redisHost ? "immich-redis",
    timeZone ? "America/Indiana/Indianapolis",
    container_name ? "immich-server",
    restart ? "always",
    port ? 2283,
    devices ? [],
    depends_on ? {
      "immich-db" = {condition = "service_healthy";};
      "immich-redis" = {condition = "service_healthy";};
    },
    environment ? {},
    volumes ? [],
  }: {
    inherit domains container_name image restart networks depends_on devices;
    caddy_port = port;
    environment =
      {
        TZ = timeZone;
        DB_HOSTNAME = dbHost;
        DB_PORT = "5432";
        DB_USERNAME = dbUser;
        DB_DATABASE_NAME = dbName;
        REDIS_HOSTNAME = redisHost;
      }
      // environment;
    envSecrets = {
      DB_PASSWORD = dbPasswordSecret;
    };
    volumes = volumes ++ ["${dataDir}:/data"];
  };

  flake.services.immich-machine-learning = {
    networks ? [],
    image ? config.flake.lib.image "ghcr.io/immich-app/immich-machine-learning",
    cacheDir,
    container_name ? "immich-machine-learning",
    restart ? "always",
    devices ? ["/dev/dri:/dev/dri" "/dev/kfd:/dev/kfd"],
    environment ? {},
  }: {
    inherit container_name image restart networks devices environment;
    out.group_add = ["video"];
    volumes = ["${cacheDir}:/cache"];
  };
}
