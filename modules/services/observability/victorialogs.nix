{
  config,
  lib,
  ...
}: {
  flake.services.victorialogs = {
    domains ? [],
    ingestionAuthFiles,
    networks ? [],
    container_name ? "victorialogs",
    restart ? "unless-stopped",
    image ? config.flake.lib.image "victoriametrics/victoria-logs",
    port ? 9000,
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
    assert lib.assertMsg (ingestionAuthFiles != []) "victorialogs requires nonempty ingestionAuthFiles for authenticated ingestion"; {
      inherit domains;
      inherit container_name;
      inherit image;
      inherit restart;
      inherit networks;
      caddy_port = port;
      caddyRaw = lib.optionalString (domains != []) ''
        ${lib.concatStringsSep ", " domains} {
            @ingest {
                method POST
                path /insert/loki/api/v1/push
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
      volumes = volumes ++ ["${dataDir}:/victoria-logs-data:rw"];
      command =
        [
          "--storageDataPath=/victoria-logs-data"
          "--httpListenAddr=:${builtins.toString port}"
        ]
        ++ command;
    };
}
