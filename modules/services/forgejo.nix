{...}: {
  flake.services.forgejo = {
    domains ? [],
    networks ? [],
    image ? "codeberg.org/forgejo/forgejo:14",
    volumes ? [],
    dataDir ? "/home/magicbox/data/forgejo"
  }: {
    inherit domains;
    container_name = "forgejo";
    postgres = true;
    postgresEnv = {
      host = "FORGEJO__database__HOST";
      database = "FORGEJO__database__NAME";
      user = "FORGEJO__database__USER";
      passwordFile = "FORGEJO__database__PASSWD_URI";
    };
    environment = {
      USER_UID = 1000;
      USER_GID = 1000;
      FORGEJO__database__DB_TYPE = "postgres";
    };
    inherit image;
    restart = "unless-stopped";
    caddy_port = 3000;
    inherit networks;
    volumes = volumes ++ [ "${dataDir}:/data" "/etc/localtime:/etc/localtime:ro" ];
  };
}
