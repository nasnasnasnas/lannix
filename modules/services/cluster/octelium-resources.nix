{inputs, ...}: {
  # Octelium's own resources (Service, Policy, User, Group, ...) declared as
  # nix attrsets and converged with `octeliumctl apply` on every switch/boot.
  # These live in Octelium's API (backed by its Postgres), not in Kubernetes,
  # so k3s manifests can't carry them. Imported by remotebox only, like the
  # datastores: exactly one node should own the apply.
  #
  # This is a systemd oneshot, not an activation script: it needs the network,
  # k3s, opnix and the Octelium API to be up, and must retry/skip cleanly
  # before the cluster is bootstrapped — none of which activation scripts
  # (synchronous, early, offline) can do.
  flake.modules.nixos.octelium-resources = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.octelium-cluster;
    domain = "octelium.szpunar.cloud";
    tokenPath = "/var/lib/opnix/secrets/octelium/apply-token";
    octeliumctl = "${pkgs.octeliumctl}/bin/octeliumctl";
    yaml = pkgs.formats.yaml {};

    # One multi-document YAML file, in list order.
    resourcesFile = pkgs.runCommand "octelium-resources.yaml" {} ''
      for f in ${
        lib.concatMapStringsSep " "
        (r: yaml.generate "octelium-${lib.toLower r.kind}-${r.metadata.name}.yaml" r)
        cfg.resources
      }; do
        cat "$f" >>"$out"
        echo "---" >>"$out"
      done
    '';
  in {
    imports = [inputs.self.modules.nixos.opnix];

    options.octelium-cluster.resources = lib.mkOption {
      type = lib.types.listOf yaml.type;
      default = [];
      description = ''
        Octelium resources (kind/metadata/spec attrsets, exactly what you'd
        feed to `octeliumctl apply -f`). Applied by the
        octelium-resources-apply oneshot on remotebox.
      '';
      example = lib.literalExpression ''
        [
          {
            kind = "Service";
            metadata.name = "hello";
            spec = {
              mode = "HTTP";
              isPublic = true;
              config.upstream.url = "http://hello.default.svc";
            };
          }
        ]
      '';
    };

    # Everything below is inert until the first resource is declared, so the
    # module can be imported before the `Octelium Apply Token` 1Password item
    # or the cluster itself exists.
    config = lib.mkIf (cfg.resources != []) {
      services.onepassword-secrets.secrets.octeliumApplyToken = {
        path = tokenPath;
        reference = "op://Secrets/Octelium Apply Token/password";
        mode = "0600";
      };

      systemd.services.octelium-resources-apply = {
        description = "Apply declarative Octelium resources via octeliumctl";
        after = ["network-online.target" "k3s.service" "opnix-secrets.service"];
        wants = ["network-online.target" "k3s.service" "opnix-secrets.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          if [ ! -s ${tokenPath} ]; then
            echo "no apply token at ${tokenPath}; skipping" >&2
            exit 0
          fi

          export OCTELIUM_AUTH_TOKEN="$(cat ${tokenPath})"
          export OCTELIUM_DOMAIN=${domain}

          # Fails until `octops init` + TLS + the apply Credential exist; stay
          # green then instead of wedging the switch — the next boot/switch
          # (or a manual `systemctl restart octelium-resources-apply`) retries.
          for _ in $(seq 12); do
            if ${octeliumctl} apply -f ${resourcesFile}; then
              echo "octelium resources applied"
              exit 0
            fi
            sleep 10
          done
          echo "WARNING: octelium resources NOT applied (cluster not bootstrapped yet?)" >&2
          exit 0
        '';
      };
    };
  };
}
