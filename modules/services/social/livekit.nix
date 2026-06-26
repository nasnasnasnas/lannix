{...}: {
  # LiveKit SFU for Matrix RTC (Element Call).
  #
  # HTTP/WS is reverse-proxied at matrix-rtc.szp.lol/livekit/sfu/ via a single combined caddy
  # block that ALSO routes /sfu/get to the lk-jwt auth-service (so only this service carries the
  # matrix-rtc.szp.lol domain — avoids a duplicate DNS record). For caddy to reach auth-service,
  # the caddy container joins the app network via caddy.extraNetworks.
  #
  # Media is published directly (rtc tcp 7881 + UDP range). TURNS (tcp 5349) is terminated by
  # Caddy's layer4 (set via the host caddy.globalConfig) and proxied plain to livekit:5349, per
  # livekit.yaml's `external_tls: true`. livekit.yaml is an opnix file secret (carries the API key).
  flake.services.livekit = {
    domains ? [],
    networks ? [],
    configSecret,
    authBackend ? "auth-service:8080",
    livekitBackend ? "livekit:7880",
    container_name ? "livekit",
    image ? "livekit/livekit-server:latest",
    restart ? "unless-stopped",
    port ? 7880,
    rtcTcpPort ? 7881,
    udpRange ? "50100-50200",
    depends_on ? ["auth-service"],
  }: let
    rtcHost = builtins.head domains;
    rtcDomain = builtins.replaceStrings ["https://" "http://"] ["" ""] rtcHost;
    turnDomain = "turn.${rtcDomain}";
  in {
    inherit domains container_name image restart networks depends_on;
    caddy_port = port;
    command = ["--config" "/etc/livekit.yaml"];
    caddyRaw = ''
      ${rtcDomain} {
          handle /sfu/get* {
              # Preflight: answer OPTIONS directly, WITH the CORS headers (a bare 204 would
              # make the browser block the real request).
              @options method OPTIONS
              handle @options {
                  header Access-Control-Allow-Origin "*"
                  header Access-Control-Allow-Methods "POST, OPTIONS"
                  header Access-Control-Allow-Headers "Accept, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization"
                  header Access-Control-Max-Age "3600"
                  respond 204
              }
              # Actual request: set the headers on the proxied response via header_down
              # (a top-level `header` is not reliably applied to reverse_proxy responses).
              handle {
                  reverse_proxy ${authBackend} {
                      header_down Access-Control-Allow-Origin "*"
                      header_down Access-Control-Allow-Methods "POST, OPTIONS"
                      header_down Access-Control-Allow-Headers "Accept, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization"
                  }
              }
          }
          handle /livekit/sfu/* {
              uri strip_prefix /livekit/sfu
              reverse_proxy ${livekitBackend}
          }

          tls {
              dns cloudflare {env.CF_API_TOKEN}
              resolvers 1.1.1.1
          }
      }

      # Cert primer: makes Caddy obtain/manage a cert for the TURNS hostname (via DNS-01) so
      # the layer4 TLS terminator on :5349 (host caddy.globalConfig) can reuse it.
      ${turnDomain} {
          tls {
              dns cloudflare {env.CF_API_TOKEN}
              resolvers 1.1.1.1
          }
          respond 204
      }
    '';
    fileSecrets = {
      "/etc/livekit.yaml" = configSecret;
    };
    ports = [
      "${toString rtcTcpPort}:${toString rtcTcpPort}"
      "${udpRange}:${udpRange}/udp"
    ];
  };
}
