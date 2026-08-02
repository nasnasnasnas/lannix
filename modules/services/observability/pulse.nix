{config, ...}: {
  flake.services.pulse = {
    domains ? [],
    networks ? [],
    image ? config.flake.lib.image "git.szpunar.cloud/nea/pulse",
    envSecrets ? {},
    fileSecrets ? {},
    pgUrlSpecs ? [],
    environment ? {},
    env_file ? [],
  }:
    {
      inherit domains;
      container_name = "pulse";
      inherit image;
      inherit envSecrets fileSecrets pgUrlSpecs;
      restart = "unless-stopped";
      caddy_port = 3000;
      healthcheck = {
        test = ["CMD" "bun" "-e" "fetch('http://127.0.0.1:3000/').then(r=>process.exit(r.status<500?0:1)).catch(()=>process.exit(1))"];
        interval = "30s";
        timeout = "5s";
        retries = 3;
        start_period = "60s";
      };
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
