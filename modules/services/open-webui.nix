{...}: {
  flake.services.open-webui = {
    domains ? [],
    networks ? [],
    image ? "ghcr.io/open-webui/open-webui:main",
    volumes ? [],
    dataDir ? "/home/magicbox/data/open-webui",
    ollamaUrl ? "http://host.docker.internal:11434",
  }: {
    inherit domains;
    container_name = "open-webui";
    inherit image;
    restart = "unless-stopped";
    caddy_port = 8080;
    extra_hosts = ["host.docker.internal:host-gateway"];
    environment = {
      OLLAMA_BASE_URL = ollamaUrl;
    };
    inherit networks;
    volumes = volumes ++ [ "${dataDir}:/app/backend/data" ];
  };
}
