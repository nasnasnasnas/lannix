{
  config,
  lib,
  ...
}: {
  flake.services.victoriametrics = {
    domains ? [],
    ingestionAuthFiles,
    networks ? [],
    container_name ? "victoriametrics",
    restart ? "unless-stopped",
    image ? config.flake.lib.image "victoriametrics/victoria-metrics",
    port ? 8428,
    environment ? {},
    volumes ? [],
    user ? "1000:100",
    plugins ? [],
    tz ? "America/Indiana/Indianapolis",
    command ? [],
    dataDir,
  }: let
    parts = builtins.match "([^:]+):([^:]+)" user;
    uid = builtins.elemAt parts 0;
    gid = builtins.elemAt parts 1;
  in
    assert lib.assertMsg (ingestionAuthFiles != []) "victoriametrics requires nonempty ingestionAuthFiles for authenticated ingestion"; {
      inherit domains;
      inherit container_name;
      inherit image;
      inherit restart;
      inherit networks;
      healthcheck = {
        test = ["CMD" "wget" "-q" "-O" "/dev/null" "http://127.0.0.1:${builtins.toString port}/health"];
        interval = "30s";
        timeout = "5s";
        retries = 3;
        start_period = "30s";
      };
      caddy_port = port;
      caddyRaw = lib.optionalString (domains != []) ''
        ${lib.concatStringsSep ", " domains} {
            @ingest {
                method POST
                path /prometheus/api/v1/write
            }
            handle @ingest {
                basic_auth {
                    ${lib.concatMapStringsSep "\n            " (path: "import ${path}") ingestionAuthFiles}
                }
                reverse_proxy ${container_name}:${toString port} {
                    header_up -Authorization
                }
            }
            handle {
                respond 404
            }
            tls {
                dns cloudflare {env.CF_API_TOKEN}
                resolvers 1.1.1.1
            }
        }
      '';
      environment =
        {
          PUID = uid;
          PGID = gid;
          TZ = tz;
        }
        // environment;
      volumes = volumes ++ ["${dataDir}:/victoria-metrics-data:rw"];
      command =
        [
          "--storageDataPath=/victoria-metrics-data"
          "--httpListenAddr=:${builtins.toString port}"
          "--selfScrapeInterval=5s"
        ]
        ++ command;
    };
}
