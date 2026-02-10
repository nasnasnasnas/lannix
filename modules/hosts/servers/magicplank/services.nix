{inputs, ...}: {
  flake.modules.nixos.magicplank = inputs.self.lib.mkHostServices {
    publicIPs = ["107.219.61.126" "100.100.165.5"];
    services = with inputs.self.services; [
      (nextcloud {domains = ["https://next.szpunar.cloud"];})
    ];
  };
}
