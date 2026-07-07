{inputs, ...}: {
  # Octelium's Postgres + Redis, deployed declaratively through k3s's
  # auto-deploy manifests. Only the cluster-init node (remotebox) imports this:
  # every k3s server applies its own manifest dir, so exactly one node must own
  # these AddOns. Passwords never touch the nix store: opnix materializes them
  # on disk and a oneshot turns them into k8s Secrets the pods reference.
  flake.modules.nixos.octelium-datastores = {
    config,
    lib,
    pkgs,
    ...
  }: let
    ns = "octelium";
    pgSecretPath = "/var/lib/opnix/secrets/octelium/pg-password";
    redisSecretPath = "/var/lib/opnix/secrets/octelium/redis-password";
    kubectl = "${config.services.k3s.package}/bin/k3s kubectl";
  in {
    imports = [inputs.self.modules.nixos.opnix];

    services.onepassword-secrets.secrets = {
      octeliumPgPassword = {
        path = pgSecretPath;
        reference = "op://Secrets/Octelium Postgres/password";
        mode = "0600";
      };
      octeliumRedisPassword = {
        path = redisSecretPath;
        reference = "op://Secrets/Octelium Redis/password";
        mode = "0600";
      };
    };

    services.k3s.manifests.octelium-datastores.content = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = ns;
      }
      {
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          name = "postgres-data";
          namespace = ns;
        };
        spec = {
          # local-path (k3s default StorageClass): node-local, RWO.
          accessModes = ["ReadWriteOnce"];
          resources.requests.storage = "10Gi";
        };
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "postgres";
          namespace = ns;
          labels.app = "postgres";
        };
        spec = {
          replicas = 1;
          # RWO volume: never run old+new pods side by side.
          strategy.type = "Recreate";
          selector.matchLabels.app = "postgres";
          template = {
            metadata.labels.app = "postgres";
            spec = {
              containers = [
                {
                  name = "postgres";
                  image = "postgres:17";
                  ports = [{containerPort = 5432;}];
                  env = [
                    {
                      name = "POSTGRES_USER";
                      value = "octelium";
                    }
                    {
                      name = "POSTGRES_DB";
                      value = "octelium";
                    }
                    {
                      name = "POSTGRES_PASSWORD";
                      valueFrom.secretKeyRef = {
                        name = "octelium-postgres-auth";
                        key = "password";
                      };
                    }
                  ];
                  volumeMounts = [
                    {
                      name = "data";
                      mountPath = "/var/lib/postgresql/data";
                      subPath = "pgdata";
                    }
                  ];
                }
              ];
              volumes = [
                {
                  name = "data";
                  persistentVolumeClaim.claimName = "postgres-data";
                }
              ];
            };
          };
        };
      }
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "postgres";
          namespace = ns;
        };
        spec = {
          selector.app = "postgres";
          ports = [
            {
              port = 5432;
              targetPort = 5432;
            }
          ];
        };
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "redis";
          namespace = ns;
          labels.app = "redis";
        };
        spec = {
          replicas = 1;
          selector.matchLabels.app = "redis";
          template = {
            metadata.labels.app = "redis";
            spec.containers = [
              {
                name = "redis";
                image = "redis:7";
                # Cache/pubsub only for Octelium; no persistence needed.
                args = ["--requirepass" "$(REDIS_PASSWORD)"];
                ports = [{containerPort = 6379;}];
                env = [
                  {
                    name = "REDIS_PASSWORD";
                    valueFrom.secretKeyRef = {
                      name = "octelium-redis-auth";
                      key = "password";
                    };
                  }
                ];
              }
            ];
          };
        };
      }
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "redis";
          namespace = ns;
        };
        spec = {
          selector.app = "redis";
          ports = [
            {
              port = 6379;
              targetPort = 6379;
            }
          ];
        };
      }
    ];

    # Bridges the opnix-materialized passwords into k8s Secrets. Until this has
    # run, the datastore pods sit in CreateContainerConfigError and converge on
    # their own once the Secrets appear.
    systemd.services.octelium-datastore-secrets = {
      description = "Create Octelium datastore auth Secrets from opnix files";
      after = ["k3s.service" "opnix-secrets.service"];
      wants = ["k3s.service" "opnix-secrets.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        for _ in $(seq 60); do
          if ${kubectl} get --raw /readyz >/dev/null 2>&1; then
            break
          fi
          sleep 5
        done

        ${kubectl} create namespace ${ns} --dry-run=client -o yaml \
          | ${kubectl} apply -f -

        ${kubectl} create secret generic octelium-postgres-auth \
          --namespace ${ns} \
          --from-file=password=${pgSecretPath} \
          --dry-run=client -o yaml \
          | ${kubectl} apply -f -

        ${kubectl} create secret generic octelium-redis-auth \
          --namespace ${ns} \
          --from-file=password=${redisSecretPath} \
          --dry-run=client -o yaml \
          | ${kubectl} apply -f -
      '';
    };
  };
}
