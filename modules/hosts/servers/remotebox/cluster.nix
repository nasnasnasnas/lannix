{inputs, ...}: {
  flake.modules.nixos.remotebox = {
    imports = [
      inputs.self.modules.nixos.octelium-node
      # Octelium's Postgres/Redis manifests live on the cluster-init node only.
      inputs.self.modules.nixos.octelium-datastores
      # Same for the octeliumctl-applied Octelium resources.
      inputs.self.modules.nixos.octelium-resources
    ];

    octelium-cluster = {
      nodeIP = "100.117.147.116";
      clusterInit = true;
      octeliumRoles = ["controlplane" "dataplane"];
      openPublicDataplanePorts = true;

      # Octelium Services/Policies/Users as attrsets; applied by the
      # octelium-resources-apply oneshot once the cluster is bootstrapped
      # (see cluster README). Example:
      #
      # resources = [
      #   {
      #     kind = "Service";
      #     metadata.name = "hello";
      #     spec = {
      #       mode = "HTTP";
      #       isPublic = true;
      #       config.upstream.url = "http://hello.default.svc";
      #     };
      #   }
      # ];
      resources = [];
    };
  };
}
