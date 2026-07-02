{config, ...}: {
  flake.services.umami = {
    domains ? [],
    networks ? [],
    image ? config.flake.lib.image "ghcr.io/umami-software/umami",
    volumes ? [],
    appSecret ? "op://Secrets/Umami/password",
    envSecrets ? {},
  }: {
    inherit domains;
    container_name = "umami";
    postgres = true;
    # Umami only accepts a single DATABASE_URL connection string (postgresql://…),
    # so the shared-host password is URL-encoded and injected at runtime.
    postgresEnv = {
      url = "DATABASE_URL";
      urlScheme = "postgresql";
    };
    # APP_SECRET signs sessions/tokens; sourced from 1Password, overridable per host.
    envSecrets =
      {
        APP_SECRET = appSecret;
      }
      // envSecrets;
    inherit image;
    restart = "unless-stopped";
    caddy_port = 3000;
    inherit networks volumes;
  };
}
