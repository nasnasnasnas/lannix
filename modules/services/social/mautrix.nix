{...}: {
  # mautrix-* puppeting bridges (telegram / signal / discord). Each keeps its own SQLite
  # database in dataDir. config.yaml and registration.yaml are opnix file secrets
  # (registration.yaml is also mounted into Synapse as an app_service_config_file).
  # Set domains (+ caddy_port via webPort) only for bridges that expose an HTTP endpoint
  # (discord's media proxy, port 29334).
  flake.services.mautrix = {
    bridge,
    networks ? [],
    dataDir,
    configSecret,
    registrationSecret,
    domains ? [],
    webPort ? null,
    image ? "dock.mau.dev/mautrix/${bridge}:latest",
    restart ? "unless-stopped",
    depends_on ? ["synapse"],
  }: {
    container_name = "mautrix-${bridge}";
    inherit image restart networks depends_on;
    fileSecrets = {
      "/data/config.yaml" = configSecret;
      "/data/registration.yaml" = registrationSecret;
    };
    volumes = ["${dataDir}:/data"];
  }
  // (
    if webPort == null
    then {}
    else {
      inherit domains;
      caddy_port = webPort;
    }
  );
}
