{config, ...}: {
  # Synapse Matrix homeserver.
  #
  # Config is split into a directory (SYNAPSE_CONFIG_PATH points at /config, a dir):
  #   - /config/homeserver.yaml  : repo-managed, NO secrets (mounted from homeserverConfig)
  #   - /config/zz-secrets.yaml  : opnix file secret; owns the whole `database` block plus the
  #                                registration_shared_secret / macaroon_secret_key / form_secret
  #                                scalars (Synapse merges config files shallowly by top-level
  #                                key, so secret top-level keys must be omitted from homeserver.yaml).
  # The signing key and each app-service registration.yaml are opnix file secrets mounted into /data
  # (registration files are shared with the bridge containers).
  flake.services.synapse = {
    domains ? [],
    networks ? [],
    dataDir,
    homeserverConfig ? ./synapse/homeserver.yaml,
    logConfig ? ./synapse/szp.lol.log.config,
    secretsFragment,
    signingKeySecret,
    serverName ? "szp.lol",
    appserviceRegistrations ? {},
    container_name ? "synapse",
    image ? config.flake.lib.image "docker.io/matrixdotorg/synapse",
    restart ? "unless-stopped",
    port ? 8008,
    depends_on ? ["synapse-db"],
  }: {
    inherit domains container_name image restart networks depends_on;
    caddy_port = port;
    environment = {
      SYNAPSE_CONFIG_PATH = "/config";
    };
    fileSecrets =
      {
        "/config/zz-secrets.yaml" = secretsFragment;
        "/data/${serverName}.signing.key" = signingKeySecret;
      }
      // appserviceRegistrations;
    volumes = [
      "${dataDir}:/data"
      "${homeserverConfig}:/config/homeserver.yaml:ro"
      "${logConfig}:/data/${serverName}.log.config:ro"
    ];
  };
}
