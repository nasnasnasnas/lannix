{ inputs, lib, ... }: {
  flake.deploy = {
    sshUser = "root";
    user = "root";
    sshOpts = ["-o" "StrictHostKeyChecking=accept-new"];
    nodes = {
      magicbox = {
        hostname = "magicbox";
        profiles.system.path =
          inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.magicbox;
      };
      remotebox = {
        hostname = "remotebox";
        profiles.system.path =
          inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.remotebox;
      };
      magicplank = {
        hostname = "magicplank";
        profiles.system.path =
          inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.magicplank;
      };
    };
  };

  # Alias so jobs run `nix run .#deploy-rs` (package has meta.mainProgram = "deploy")
  # and the build job can cache it in attic with `nix build .#deploy-rs`.
  perSystem = { system, ... }: {
    packages.deploy-rs =
      lib.mkIf (system == "x86_64-linux")
        inputs.deploy-rs.packages.${system}.deploy-rs;
  };
}
