{config, lib, ...}: {
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
  

  config.perSystem = {pkgs, ...}: let
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

        cat ${dnsConfigHeader} ${generateScript} > "$TMPFILE"
        bun run "$TMPFILE" > Pulumi.yaml

        echo "Generated Pulumi.yaml"
        echo "Running pulumi up..."
        pulumi login -l
        pulumi stack select cloudflare --create
        pulumi up --refresh --yes --stack=cloudflare "$@"

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
