{...}: {
  flake.services.atticd = {
    domains ? [],
    networks ? [],
    image ? "ghcr.io/zhaofengli/attic:latest",
    dataDir ? "/home/magicbox/data/attic",
    tokenSecret ? "op://Secrets/Attic Server Token/password",
    allowedHost ? "attic.szpunar.cloud",
    apiEndpoint ? "https://attic.szpunar.cloud/",
  }: let
    serverToml = builtins.toFile "attic-server.toml" ''
      listen = "[::]:8080"
      allowed-hosts = ["${allowedHost}"]
      api-endpoint = "${apiEndpoint}"

      [database]
      url = "sqlite:///data/server.db?mode=rwc"

      [storage]
      type = "local"
      path = "/data/storage"

      [chunking]
      nar-size-threshold = 65536
      min-size = 16384
      avg-size = 65536
      max-size = 262144

      [compression]
      type = "zstd"

      [garbage-collection]
      interval = "12 hours"
    '';
  in {
    inherit domains image networks;
    container_name = "atticd";
    restart = "unless-stopped";
    caddy_port = 8080;
    command = ["-f" "/attic/server.toml"];
    envSecrets = {
      ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64 = tokenSecret;
    };
    volumes = [
      "${serverToml}:/attic/server.toml:ro"
      "${dataDir}:/data"
    ];
  };
}
