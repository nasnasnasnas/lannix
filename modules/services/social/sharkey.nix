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
    depends_on ? ["sharkey-db" "sharkey-redis"],
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
  };
}
