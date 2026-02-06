{
  config,
  lib,
  ...
}: {
  options.flake.dnsRecords = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf (lib.types.submodule {
      options = {
        name = lib.mkOption {type = lib.types.str;};
        type = lib.mkOption {type = lib.types.str;};
        content = lib.mkOption {type = lib.types.str;};
        ttl = lib.mkOption {
          type = lib.types.int;
          default = 1;
        };
        proxied = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };
    }));
    default = {};
  };

  config = let
    # Parse a Caddy domain URL into { name, zone }
    # e.g. "https://stream.szpunar.cloud" -> { name = "stream"; zone = "szpunar.cloud"; }
    parseCaddyDomain = domainUrl: let
      stripped = lib.removePrefix "https://" (lib.removePrefix "http://" domainUrl);
      parts = lib.splitString "." stripped;
      len = builtins.length parts;
      zone = lib.concatStringsSep "." (lib.drop (len - 2) parts);
      subdomain = lib.concatStringsSep "." (lib.take (len - 2) parts);
    in {
      inherit zone;
      name = if subdomain == "" then "@" else subdomain;
    };

    # Auto-generate A records from host.caddyDomains + host.publicIPs in each nixosConfiguration.
    # Each domain gets one A record per IP.
    autoRecords = let
      perHost = lib.mapAttrsToList (_hostName: nixosConfig: let
        hostCfg = nixosConfig.config;
        ips = hostCfg.host.publicIPs or [];
        domains = hostCfg.host.caddyDomains or [];
      in
        lib.concatMap (d: let
          parsed = parseCaddyDomain d;
        in
          map (ip: {
            zone = parsed.zone;
            record = {
              name = parsed.name;
              type = "A";
              content = ip;
            };
          })
          ips)
        domains)
      config.flake.nixosConfigurations;

      allRecords = lib.concatLists perHost;
      grouped = lib.groupBy (r: r.zone) allRecords;
    in
      lib.mapAttrs (_: entries: map (e: e.record) entries) grouped;
  in {
    flake.dnsRecords = autoRecords;

    perSystem = {pkgs, ...}: let
      dnsConfig = builtins.toJSON {
        domains =
          lib.mapAttrs (_domain: records:
            map (r: {inherit (r) name type content ttl proxied;}) records)
          config.flake.dnsRecords;
      };

      dnsConfigHeader = pkgs.writeText "dns-config.ts" "const DNS_CONFIG = ${dnsConfig};\n";
      generateScript = ./pulumi-dns-gen/generate.ts;
    in {
      packages.pulumi-dns-gen = pkgs.writeShellApplication {
        name = "pulumi-dns-gen";
        runtimeInputs = [pkgs.pulumi-bin pkgs.bun];
        text = ''
          TMPFILE=$(mktemp --suffix=.ts)
          trap 'rm -f "$TMPFILE"' EXIT

          # Generate Pulumi.yaml first (needed for pulumi stack commands)
          cat ${dnsConfigHeader} ${generateScript} > "$TMPFILE"
          bun run "$TMPFILE" > Pulumi.yaml
          echo "Generated Pulumi.yaml"

          pulumi login -l
          pulumi stack init cloudflare 2>/dev/null || true
          pulumi stack select cloudflare

          # Only import existing Cloudflare records on first run (empty stack).
          # Re-importing already-managed resources causes state conflicts.
          RESOURCE_COUNT=$(pulumi stack export 2>/dev/null \
            | grep -c '"urn":' || true)
          if [ "$RESOURCE_COUNT" -le 1 ]; then
            echo "First run detected — enabling import of existing records"
            export ENABLE_IMPORT=1
            # Re-generate with imports enabled
            bun run "$TMPFILE" > Pulumi.yaml
          fi

          echo "Running pulumi up..."
          pulumi up --refresh --yes "$@"

          echo "Removing Pulumi.yaml..."
          rm Pulumi.yaml
        '';
      };

      # apps.pulumi-dns-gen = {
      #   type = "app";
      #   program = "${pkgs.lib.getExe inputs.self.packages.pulumi-dns-gen}";
      # };
    };
  };
}
