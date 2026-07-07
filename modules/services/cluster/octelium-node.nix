{inputs, ...}: {
  # Shared module for the 3-node k3s cluster (HA embedded etcd over Tailscale)
  # that hosts the Octelium + Cordium platform. Octelium/Cordium themselves are
  # installed onto k8s with octops (see README.md in this directory); this
  # module only provides the Kubernetes substrate, node labels, ports and CLIs.
  flake.modules.nixos.octelium-node = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.octelium-cluster;
    tokenPath = "/var/lib/opnix/secrets/k3s/token";
    # remotebox's tailscale IP: the cluster-init etcd member the others join.
    initServerIP = "100.117.147.116";
  in {
    imports = [inputs.self.modules.nixos.opnix];

    options.octelium-cluster = {
      nodeIP = lib.mkOption {
        type = lib.types.str;
        description = "This node's Tailscale IPv4 (tailscale ip -4). Intra-cluster traffic runs over tailscale0.";
      };
      clusterInit = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether this node initializes the embedded etcd cluster. Exactly one node (remotebox) sets this.";
      };
      octeliumRoles = lib.mkOption {
        type = lib.types.listOf (lib.types.enum ["controlplane" "dataplane" "cordium"]);
        default = [];
        description = "Octelium node modes applied as octelium.com/node-mode-<role>= labels.";
      };
      openPublicDataplanePorts = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Open Octelium's public WireGuard port (53820/udp) on dataplane nodes with a public IP. TCP 443 is deliberately not managed here; the dockerized Caddy already owns it (see README.md).";
      };
    };

    config = {
      services.onepassword-secrets = {
        enable = true;
        tokenFile = "/etc/op-token";
        secrets.k3sToken = {
          path = tokenPath;
          reference = "op://Secrets/k3s Cluster Token/password";
          mode = "0600";
        };
      };

      services.k3s = {
        enable = true;
        role = "server";
        clusterInit = cfg.clusterInit;
        serverAddr = lib.mkIf (!cfg.clusterInit) "https://${initServerIP}:6443";
        tokenFile = tokenPath;
        nodeIP = cfg.nodeIP;
        nodeLabel = map (r: "octelium.com/node-mode-${r}=") cfg.octeliumRoles;
        # Octelium brings its own ingress on 443, so k3s traefik/servicelb must
        # not claim 80/443. coredns, metrics-server and local-path stay enabled;
        # Cordium requires local-path's dynamic StorageClass.
        disable = ["traefik" "servicelb"];
        extraFlags = [
          "--flannel-iface=tailscale0"
          "--tls-san=${initServerIP}"
          "--tls-san=${cfg.nodeIP}"
          "--tls-san=${config.networking.hostName}"
        ];
        gracefulNodeShutdown.enable = true;
      };

      # node-ip must exist and the token must be materialized before k3s starts.
      systemd.services.k3s = {
        after = ["tailscaled.service" "opnix-secrets.service"];
        wants = ["tailscaled.service" "opnix-secrets.service"];
      };

      networking.firewall.interfaces."tailscale0" = {
        allowedTCPPorts = [
          6443 # kubernetes API
          10250 # kubelet
        ];
        allowedTCPPortRanges = [
          {
            from = 2379; # etcd client/peer
            to = 2380;
          }
        ];
        allowedUDPPorts = [8472]; # flannel vxlan
      };

      networking.firewall.allowedUDPPorts =
        lib.mkIf (cfg.openPublicDataplanePorts && lib.elem "dataplane" cfg.octeliumRoles) [53820];

      environment.systemPackages = with pkgs; [
        octelium
        octeliumctl
        octops
        cordium
        kubectl
        k9s
      ];
    };
  };
}
