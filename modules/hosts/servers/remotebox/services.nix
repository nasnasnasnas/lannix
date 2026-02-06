{inputs, ...}: {
  flake.modules.nixos.remotebox = inputs.self.lib.mkHostServices {
    publicIP = "45.8.201.111";
    services = with inputs.self.services; [
      (helloworld {domains = ["https://helloworld.szpunar.cloud"];})
    ];
  };
}
