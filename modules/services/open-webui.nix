{...}: {
  flake.services.open-webui = {
    domains ? [],
    networks ? [],
    image ? "ghcr.io/open-webui/open-webui:main",
    volumes ? [],
    dataDir ? "/home/magicbox/data/open-webui",
    ollamaUrl ? "http://host.docker.internal:11434",
    oauthEnvFile ? null,
    oidc ? null,
  }: let
    oidcEnv =
      if oidc != null
      then {
        ENABLE_OAUTH_SIGNUP = "true";
        ENABLE_LOGIN_FORM = "false";
        ENABLE_PASSWORD_AUTH = "false";
        OPENID_PROVIDER_URL = oidc.providerUrl;
        OPENID_REDIRECT_URI = oidc.redirectUri;
        OAUTH_PROVIDER_NAME = oidc.providerName or "SSO";
        OAUTH_SCOPES = oidc.scopes or "openid email profile";
        WEBUI_URL = builtins.head domains;
      }
      else {};
    envFiles = if oauthEnvFile != null then [oauthEnvFile] else [];
  in {
    inherit domains;
    container_name = "open-webui";
    inherit image;
    restart = "unless-stopped";
    caddy_port = 8080;
    extra_hosts = ["host.docker.internal:host-gateway"];
    environment =
      {
        OLLAMA_BASE_URL = ollamaUrl;
      }
      // oidcEnv;
    env_file = envFiles;
    inherit networks;
    volumes = volumes ++ [ "${dataDir}:/app/backend/data" ];
  };
}
