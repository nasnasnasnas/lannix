{inputs, ...}: {
  flake.modules.nixos.remotebox = inputs.self.lib.mkHostServices {
    publicIPs = ["45.8.201.111" "100.117.147.116"];
    caddy = {
      envSecrets = {
        CF_API_TOKEN = "op://Secrets/Caddy Cloudflare Token for HTTPS/password";
      };
    };
    services = with inputs.self.services; [
      (helloworld {domains = ["https://helloworld.szpunar.cloud"];})
      (pocket-id {domains = ["https://auth.szpunar.cloud"];})
    ];
  };
}
