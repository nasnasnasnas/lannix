{...}: {
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    # Configuration
    zoneDomain = "szpunar.cloud";
    zoneId = "1ebe2bc9ef4bee4a5f6d9f12b15ba8f0";

    aRecords = [
      "bazarr"
      "grafana"
      "lidarr"
      "mylar"
      "nzbdav"
      "prowlarr"
      "pyroscope"
      "radarr"
      "request"
      "sabnzbd"
      "sonarr"
      "stream"
      "termix"
      "victorialogs"
      "victoriametrics"
    ];

    aRecordIP = "10.177.177.117";

    cnameRecords = [
      {
        name = "budget";
        target = "kickass-flounder.pikapod.net";
      }
      {
        name = "kickass-geese";
        target = "kickass-flounder.pikapod.net";
      }
    ];

    indent = str: "    " + builtins.replaceStrings ["\n"] ["\n    "] str;

    generateARecord = name:
      lib.concatStringsSep "\n" [
        "${name}:"
        "  type: cloudflare:Record"
        "  properties:"
        "    zoneId: \${zoneId}"
        "    name: ${name}"
        "    type: A"
        "    content: ${aRecordIP}"
        "    ttl: 1"
        "    proxied: false"
      ];

    generateCNAMERecord = {
      name,
      target,
    }:
      lib.concatStringsSep "\n" [
        "${name}:"
        "  type: cloudflare:Record"
        "  properties:"
        "    zoneId: \${zoneId}"
        "    name: ${name}"
        "    type: CNAME"
        "    content: ${target}"
        "    ttl: 1"
        "    proxied: false"
      ];

    allARecords = lib.concatMapStringsSep "\n" generateARecord aRecords;
    allCNAMERecords = lib.concatMapStringsSep "\n" generateCNAMERecord cnameRecords;

    pulumiYaml = pkgs.writeTextFile {
      name = "Pulumi.yaml";
      text = ''
        name: cloudflare-dns-${zoneDomain}
        runtime: yaml
        description: DNS configuration for ${zoneDomain}

        variables:
          zoneId: "${zoneId}"

        resources:
          # A Records
        ${indent allARecords}

          # CNAME Records
        ${indent allCNAMERecords}
      '';
    };
  in {
    packages.pulumi-dns-gen = pkgs.writeShellApplication {
      name = "pulumi-dns-gen";
      runtimeInputs = [pkgs.pulumi-bin];
      text = ''
        # Write the generated Pulumi.yaml to the current directory
        cat ${pulumiYaml} > Pulumi.yaml

        echo "Generated Pulumi.yaml"
        echo "Running pulumi preview..."

        # Run pulumi preview
        pulumi login -l
        pulumi stack select cloudflare --create
        pulumi preview --stack=cloudflare "$@"

        echo "Removing Pulumi.yaml..."
        rm Pulumi.yaml
      '';
    };

    # apps.pulumi-dns-gen = {
    #   type = "app";
    #   program = "${pkgs.lib.getExe inputs.self.packages.pulumi-dns-gen}";
    # };
  };
}
