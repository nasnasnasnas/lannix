{...}: {
  flake.services.pulse = {
    domains ? [],
    networks ? [],
    image ? "git.szpunar.cloud/nea/pulse:cefede2c2b872b750de43121a4a6e4326b86b8ca",
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
