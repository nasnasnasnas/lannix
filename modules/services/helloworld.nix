{config, ...}: {
  flake.services.helloworld = {
    domains ? [],
    networks ? [],
    image ? config.flake.lib.image "crccheck/hello-world",
  }: {
    inherit domains;
    container_name = "helloworld";
    inherit image;
    restart = "unless-stopped";
    caddy_port = 8000;
    inherit networks;
  };
}
