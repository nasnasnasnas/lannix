{inputs, ...}: {
  flake.modules.nixos.magicbox = {
    imports = [inputs.self.modules.nixos.octelium-node];

    octelium-cluster = {
      nodeIP = "100.83.201.118";
      octeliumRoles = ["dataplane" "cordium"];
      # No public IP, so Octelium WireGuard/ingress traffic never reaches this
      # node directly; it participates via the tailnet only.
      openPublicDataplanePorts = false;
    };
  };
}
