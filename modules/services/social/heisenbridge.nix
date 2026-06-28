{config, ...}: {
  # Heisenbridge (bouncer-style IRC bridge). Runs as two containers sharing one config:
  #   - heisenbridge       : the appservice itself (media = false)
  #   - heisenbridge-media : the media proxy, exposed at heisenbridge.szp.lol (media = true)
  # heisenbridge.yaml carries the as_token/hs_token and is an opnix file secret (also mounted
  # into Synapse as an app_service_config_file).
  flake.services.heisenbridge = {
    networks ? [],
    dataDir,
    configSecret,
    media ? false,
    domains ? [],
    synapseUrl ? "http://synapse:8008",
    image ? config.flake.lib.image "hif1/heisenbridge",
    restart ? "unless-stopped",
    mediaPort ? 9898,
    depends_on ? ["synapse"],
  }: let
    container_name =
      if media
      then "heisenbridge-media"
      else "heisenbridge";
    command =
      if media
      then ["-c" "/data/heisenbridge.yaml" "--media-proxy" synapseUrl]
      else ["-v" "-v" "-c" "/data/heisenbridge.yaml" synapseUrl];
  in
    {
      inherit container_name image restart networks depends_on command;
      fileSecrets = {
        "/data/heisenbridge.yaml" = configSecret;
      };
      volumes = ["${dataDir}:/data"];
    }
    // (
      if media
      then {
        inherit domains;
        caddy_port = mediaPort;
      }
      else {}
    );
}
