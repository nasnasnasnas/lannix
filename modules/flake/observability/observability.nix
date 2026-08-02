{...}: {
  # Ship host node metrics + journald logs from any NixOS host to the central
  # VictoriaMetrics / VictoriaLogs stack. Enabled via
  # `server-observability.enable = true;`.
  flake.modules.nixos.server-observability = {
    lib,
    config,
    ...
  }: let
    extraPrometheusScrapes = lib.concatStringsSep "\n" (lib.mapAttrsToList (jobName: targets: ''
      prometheus.scrape ${builtins.toJSON jobName} {
        job_name = ${builtins.toJSON jobName}
        targets = [
          ${lib.concatMapStringsSep "\n  " (target: "{ \"__address__\" = ${builtins.toJSON target} },") targets}
        ]
        forward_to = [prometheus.remote_write.default.receiver]
      }
    '') config.server-observability.extraPrometheusScrapeTargets);
    dockerLogContainers = config.server-observability.dockerLogContainers;
    dockerContainerPattern =
      lib.concatStringsSep "|" (map lib.escapeRegex dockerLogContainers);
    dockerLogs = lib.optionalString (dockerLogContainers != []) ''
      discovery.docker "selected_logs" {
        host = "unix:///var/run/docker.sock"
      }

      discovery.relabel "selected_docker_logs" {
        targets = discovery.docker.selected_logs.targets

        rule {
          source_labels = ["__meta_docker_container_name"]
          regex         = "^/(${dockerContainerPattern})$"
          action        = "keep"
        }
        rule {
          source_labels = ["__meta_docker_container_name"]
          regex         = "^/(.*)$"
          replacement   = "$1"
          target_label  = "container"
        }
      }

      loki.source.docker "selected" {
        host       = "unix:///var/run/docker.sock"
        targets    = discovery.relabel.selected_docker_logs.output
        forward_to = [loki.write.default.receiver]
        labels = {
          host = "${config.networking.hostName}",
          job  = "integrations/docker",
        }
      }
    '';
  in {
    options.server-observability = {
      enable = lib.mkEnableOption "Alloy node metrics + journald log shipping to the central observability stack";
      metricsUrl = lib.mkOption {
        type = lib.types.str;
        default = "https://victoriametrics.szpunar.cloud/prometheus/api/v1/write";
        description = "Prometheus remote_write endpoint for node metrics.";
      };
      logsUrl = lib.mkOption {
        type = lib.types.str;
        default = "https://victorialogs.szpunar.cloud/insert/loki/api/v1/push";
        description = "Loki push endpoint for journald logs.";
      };
      extraPrometheusScrapeTargets = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        default = {};
        description = "Additional Prometheus scrape jobs, keyed by job name with host:port targets.";
      };
      dockerLogContainers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Docker container names whose stdout/stderr logs Alloy ships.";
      };
    };

    config = lib.mkIf config.server-observability.enable {
      services.alloy.enable = true;
      # The service runs with DynamicUser = true; defining the user statically lets
      # systemd reuse it (stable UID) and grants the journald/adm supplementary groups.
      users.users.alloy = {
        isSystemUser = true;
        group = "alloy";
        extraGroups = ["adm" "systemd-journal"];
      };
      users.groups.alloy = {};
      systemd.services.alloy.serviceConfig.SupplementaryGroups =
        lib.mkIf (dockerLogContainers != []) (lib.mkAfter ["docker"]);

      environment.etc."alloy/config.alloy".text = ''
        prometheus.exporter.self "default" { }
        prometheus.scrape "metamonitoring" {
          targets = prometheus.exporter.self.default.targets
          forward_to = [prometheus.remote_write.default.receiver]
        }

        prometheus.exporter.unix "default" { }
        prometheus.scrape "node" {
          job_name = "integrations/unix"
          targets = prometheus.exporter.unix.default.targets
          forward_to = [prometheus.relabel.node.receiver]
        }
        prometheus.relabel "node" {
          forward_to = [prometheus.remote_write.default.receiver]

          rule {
            replacement  = "${config.networking.hostName}"
            target_label = "instance"
          }
        }

        ${extraPrometheusScrapes}

        prometheus.remote_write "default" {
          endpoint {
            url = "${config.server-observability.metricsUrl}"
          }
        }

        loki.source.journal "default" {
          forward_to = [loki.relabel.journal.receiver]
          labels = {
            host = "${config.networking.hostName}",
            job  = "integrations/journal",
          }
        }

        loki.relabel "journal" {
          rule {
            source_labels = ["__journal__systemd_unit"]
            target_label  = "unit"
          }
          rule {
            source_labels = ["__journal_priority_keyword"]
            target_label  = "level"
          }
          forward_to = [loki.write.default.receiver]
        }

        ${dockerLogs}

        loki.write "default" {
          endpoint {
            url = "${config.server-observability.logsUrl}"
          }
        }
      '';
    };
  };
}
