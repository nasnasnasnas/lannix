{config, ...}: {
  # Sharkey (Misskey fork) web frontend/backend.
  # Its full config (incl. DB password + setupPassword) lives in default.yml, which is an
  # opnix file secret mounted read-only at /sharkey/.config/default.yml.
  flake.services.sharkey = {
    domains ? [],
    networks ? [],
    dataDir,
    configSecret,
    container_name ? "sharkey",
    image ? config.flake.lib.image "registry.activitypub.software/transfem-org/sharkey",
    restart ? "always",
    port ? 3000,
    depends_on ? {
      "sharkey-db" = {condition = "service_healthy";};
      "sharkey-redis" = {condition = "service_healthy";};
    },
    environment ? {},
  }: {
    inherit domains container_name image restart networks depends_on;
    caddy_port = port;
    environment =
      {
        NODE_OPTIONS = "--max-old-space-size=8192";
      }
      // environment;
    fileSecrets = {
      "/sharkey/.config/default.yml" = configSecret;
    };
    volumes = ["${dataDir}:/sharkey/files"];
    healthcheck = {
      test = ["CMD" "node" "-e" "fetch('http://127.0.0.1:3000/').then(r=>process.exit(r.status<500?0:1)).catch(()=>process.exit(1))"];
      interval = "30s";
      timeout = "10s";
      retries = 5;
      start_period = "120s";
    };
  };
}
