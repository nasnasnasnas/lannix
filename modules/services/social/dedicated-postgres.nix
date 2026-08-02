{config, ...}: {
  # A dedicated Postgres container (NOT the shared host postgres-puppy), used where an app
  # needs a specific image or initdb settings:
  #   - Synapse: stock postgres with C collation (POSTGRES_INITDB_ARGS)
  #   - Sharkey: groonga/pgroonga image for full-text search
  # The password is supplied via envSecrets (POSTGRES_PASSWORD = "op://...").
  flake.services.dedicated-postgres = {
    container_name,
    dataDir,
    networks ? [],
    image ? config.flake.lib.image "postgres:15-alpine",
    restart ? "always",
    db,
    user,
    initdbArgs ? null,
    envSecrets ? {},
    environment ? {},
  }: {
    inherit container_name image restart networks envSecrets;
    environment =
      {
        POSTGRES_DB = db;
        POSTGRES_USER = user;
      }
      // (
        if initdbArgs == null
        then {}
        else {POSTGRES_INITDB_ARGS = initdbArgs;}
      )
      // environment;
    volumes = ["${dataDir}:/var/lib/postgresql/data"];
    healthcheck = {
      test = ["CMD" "pg_isready" "-h" "127.0.0.1"];
      interval = "10s";
      timeout = "5s";
      retries = 5;
      start_period = "60s";
    };
  };
}
