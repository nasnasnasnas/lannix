{ ... }: {
  flake.services.helloworld = {
    domains ? [],
    networks ? [],
    image ? "crccheck/hello-world"
  }: {
    container_name = "helloworld";
    inherit image;
    restart = "unless-stopped";
    inherit domains;
    caddy_port = 8000;
    inherit networks;
  };
}
