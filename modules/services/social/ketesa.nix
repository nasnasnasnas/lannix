{ config, ... }: {
  flake.services.ketesa =
    {
      domains ? [ ],
      networks ? [ ],
      baseUrl ? "https://matrix.szp.lol",
      container_name ? "ketesa",
      image ? config.flake.lib.image "ghcr.io/etkecc/ketesa",
      restart ? "unless-stopped",
    }:
    let
      frontendConfig = builtins.toFile "ketesa-config.json" (
        builtins.toJSON {
          restrictBaseUrl = baseUrl;
          wellKnownDiscovery = false;
          externalAuthProvider = true;
        }
      );
    in
    {
      inherit
        domains
        networks
        container_name
        image
        restart
        ;
      caddy_port = 8080;
      volumes = [ "${frontendConfig}:/var/public/config.json:ro" ];
    };
}
