{inputs, ...}: {
  flake.modules.nixos.magicplank = {
    imports = [inputs.self.modules.nixos.octelium-node];

    octelium-cluster = {
      # PLACEHOLDER-FILL-ME: run `tailscale ip -4` on magicplank
      nodeIP = "100.0.0.0";
      octeliumRoles = ["dataplane" "cordium"];
      openPublicDataplanePorts = true;
    };
  };
}
