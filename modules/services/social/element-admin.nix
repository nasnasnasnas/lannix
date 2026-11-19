{ config, ... }: {
  flake.services.element-admin =
    {
      domains ? [ ],
      networks ? [ ],
      serverName ? "szp.lol",
      container_name ? "element-admin",
      image ? config.flake.lib.image "oci.element.io/element-admin",
      restart ? "unless-stopped",
    }:
    {
      inherit
        domains
        networks
        container_name
        image
        restart
        ;
      caddy_port = 8080;
      environment = {
        SERVER_NAME = serverName;
      };
    };
}
