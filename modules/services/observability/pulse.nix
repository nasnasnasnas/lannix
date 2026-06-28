{config, ...}: {
  flake.services.pulse = {
    domains ? [],
    networks ? [],
    image ? config.flake.lib.image "git.szpunar.cloud/nea/pulse",
    envSecrets ? {},
    environment ? {},
    env_file ? [],
  }:
    {
      inherit domains;
      container_name = "pulse";
      inherit image;
      inherit envSecrets;
      restart = "unless-stopped";
      caddy_port = 3000;
      inherit networks;
      extra_hosts = ["host.docker.internal:host-gateway"];
      environment =
        {
          PORT = "3000";
        }
        // environment;
    }
    // (
      if env_file == []
      then {}
      else {inherit env_file;}
    );
}
