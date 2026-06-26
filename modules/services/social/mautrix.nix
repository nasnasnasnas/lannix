{...}: {
  # mautrix-* puppeting bridges (telegram / signal / discord). Each keeps its own SQLite
  # database AND its config.yaml + registration.yaml in dataDir (migrated from the Pi). These
  # are NOT opnix read-only secrets: mautrix rewrites/chowns its config on startup (config
  # schema migration), so the files must be writable and owned by the bridge. Synapse reads
  # each registration.yaml separately via opnix (read-only is fine there; tokens are stable).
  # Set domains (+ caddy_port via webPort) only for bridges that expose an HTTP endpoint
  # (discord's media proxy, port 29334).
  flake.services.mautrix = {
    bridge,
    networks ? [],
    dataDir,
    domains ? [],
    webPort ? null,
    image ? "dock.mau.dev/mautrix/${bridge}:latest",
    restart ? "unless-stopped",
    depends_on ? ["synapse"],
  }: {
    container_name = "mautrix-${bridge}";
    inherit image restart networks depends_on;
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
