{...}: {
  flake.services.caddy = {
    networks ? [],
    image ? "ghcr.io/caddybuilds/caddy-cloudflare:latest",
    caddyfilePath,
    secretsEnvPath ? null,
    dataDir ? "/home/magicbox/data/caddy",
  }: {
    container_name = "caddy";
    inherit image;
    restart = "always";
    domains = [];
    caddy_port = null;
    command =
      ["caddy" "run" "--config" "/etc/caddy/Caddyfile" "--adapter" "caddyfile"]
      ++ (
        if secretsEnvPath == null
        then []
        else ["--envfile" "/etc/caddy/secrets.env"]
      );
    inherit networks;
    ports = [
      "80:80"
      "443:443"
      "443:443/udp"
    ];
    volumes =
      [
        "${caddyfilePath}:/etc/caddy/Caddyfile:ro"
        "${dataDir}:/data"
      ]
      ++ (
        if secretsEnvPath == null
        then []
        else [
          "${secretsEnvPath}:/etc/caddy/secrets.env:ro"
        ]
      );
  };
}
