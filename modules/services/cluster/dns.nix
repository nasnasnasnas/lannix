{...}: {
  # Cluster-level records for the Octelium domain. These span multiple hosts,
  # so they live here as direct dnsRecords instead of host.caddyDomains (which
  # means "served by this host's caddy"). The wildcard is required because
  # Octelium exposes every Service as <service>.octelium.szpunar.cloud.
  flake.dnsRecords."szpunar.cloud" = let
    # Publicly reachable dataplane nodes: magicplank, remotebox.
    # magicbox is dataplane too but has no public IP.
    dataplaneIPs = ["107.219.61.126" "45.8.201.111"];
    mkA = name: content: {
      inherit name content;
      type = "A";
    };
  in
    (map (mkA "octelium") dataplaneIPs)
    ++ (map (mkA "*.octelium") dataplaneIPs);
}
