{inputs, ...}: {
  flake.modules.nixos.remotebox = inputs.self.lib.mkHostServices {
    publicIPs = ["45.8.201.111" "100.117.147.116"];
    services = with inputs.self.services; [
      (helloworld {domains = ["https://helloworld.szpunar.cloud"];})
      (pocket-id {domains = ["https://auth.szpunar.cloud"];})
    ];
  };
}
