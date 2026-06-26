{
  lib,
  config,
  inputs,
  ...
}: let
  flakeConfig = config;
  vaultId = "q63632lctm4by3clskcul4gmf4";
in {
  options.flake.services = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = {};
    description = "Docker service factory functions. Each service is a function that takes parameters and returns a simplified service definition.";
  };

  config.flake.lib = {
    # Extract all Caddy domain URLs from a list of instantiated service definitions.
    # e.g. extractCaddyDomains [ (helloworld { domains = ["https://hw.example.com"]; }) ] -> ["https://hw.example.com"]
    extractCaddyDomains = services:
      lib.concatMap (s: s.domains or []) services;

    # Convert a simplified service definition to Arion service format by removing meta keys and moving service.out to out.service.
    mkArionService = serviceDef: let
      metaKeys = ["caddy_port" "domains" "out" "postgres" "postgresEnv" "envSecrets" "fileSecrets" "caddyRaw"];
      serviceAttrs = builtins.removeAttrs serviceDef metaKeys;
      outAttrs = serviceDef.out or {};
    in {
      service = serviceAttrs;
      out.service = outAttrs;
    };

    mkArionServices = services:
      lib.mapAttrs (_name: config.flake.lib.mkArionService) services;

    secretBaseDir = serviceName: "/var/lib/opnix/secrets/${serviceName}";

    envSecretPath = serviceName: envName: "${config.flake.lib.secretBaseDir serviceName}/env/${envName}";

    envFilePath = serviceName: "${config.flake.lib.secretBaseDir serviceName}/envfile";

    fileSecretHostName = containerPath: let
      pathLength = builtins.stringLength containerPath;
      withoutLeadingSlash = builtins.substring 1 (pathLength - 1) containerPath;
    in
      builtins.replaceStrings ["/"] ["-"] withoutLeadingSlash;

    fileSecretPath = serviceName: containerPath: "${config.flake.lib.secretBaseDir serviceName}/files/${config.flake.lib.fileSecretHostName containerPath}";

    validateFileSecrets = serviceName: fileSecrets: let
      containerPaths = builtins.attrNames fileSecrets;
      hostNames = map config.flake.lib.fileSecretHostName containerPaths;
      uniqueHostNames = lib.unique hostNames;
      invalidPaths = builtins.filter (path: !(lib.hasPrefix "/" path) || lib.hasInfix ".." path || config.flake.lib.fileSecretHostName path == "") containerPaths;
    in
      if invalidPaths != []
      then throw "Invalid fileSecrets paths for ${serviceName}: ${lib.concatStringsSep ", " invalidPaths}"
      else if builtins.length uniqueHostNames != builtins.length hostNames
      then throw "fileSecrets host path collision for ${serviceName}"
      else fileSecrets;

    validateEnvSecrets = serviceName: envSecrets: let
      envNames = builtins.attrNames envSecrets;
      invalidNames = builtins.filter (name: builtins.match "[A-Za-z_][A-Za-z0-9_]*" name == null) envNames;
    in
      if invalidNames != []
      then throw "Invalid envSecrets names for ${serviceName}: ${lib.concatStringsSep ", " invalidNames} (must be valid shell variable names)"
      else envSecrets;

    processServiceSecrets = s: let
      serviceName = s.container_name;
      envSecrets = config.flake.lib.validateEnvSecrets serviceName (s.envSecrets or {});
      fileSecrets = config.flake.lib.validateFileSecrets serviceName (s.fileSecrets or {});
      envSecretNames = builtins.attrNames envSecrets;
      hasEnvSecrets = envSecrets != {};
      hasFileSecrets = fileSecrets != {};
      environmentWithoutSecrets = builtins.removeAttrs (s.environment or {}) envSecretNames;
      fileSecretVolumes = map (containerPath: "${config.flake.lib.fileSecretPath serviceName containerPath}:${containerPath}:ro") (builtins.attrNames fileSecrets);
    in
      s
      // lib.optionalAttrs hasEnvSecrets {
        environment = environmentWithoutSecrets;
        env_file = (s.env_file or []) ++ [(config.flake.lib.envFilePath serviceName)];
      }
      // lib.optionalAttrs hasFileSecrets {
        volumes = (s.volumes or []) ++ fileSecretVolumes;
      };

    mkServiceSecretRegistrations = services: let
      mkSecretName = serviceName: kind: key: "secret${builtins.substring 0 16 (builtins.hashString "sha256" "${serviceName}:${kind}:${key}")}";
      envSecretAttrs = lib.concatMap (s:
        lib.mapAttrsToList (envName: ref: {
          name = mkSecretName s.container_name "env" envName;
          value = {
            reference = ref;
            path = config.flake.lib.envSecretPath s.container_name envName;
            mode = "0400";
          };
        }) (s.envSecrets or {}))
      services;
      fileSecretAttrs = lib.concatMap (s:
        lib.mapAttrsToList (containerPath: ref: {
          name = mkSecretName s.container_name "file" containerPath;
          value = {
            reference = ref;
            path = config.flake.lib.fileSecretPath s.container_name containerPath;
            mode = "0400";
          };
        }) (s.fileSecrets or {}))
      services;
    in
      builtins.listToAttrs (envSecretAttrs ++ fileSecretAttrs);

    mkSecretEnvScript = pkgs: projectName: services: let
      servicesWithEnvSecrets = builtins.filter (s: (s.envSecrets or {}) != {}) services;
      mkServiceBlock = s: let
        envDir = "${config.flake.lib.secretBaseDir s.container_name}/env";
        envFile = config.flake.lib.envFilePath s.container_name;
        lines = lib.mapAttrsToList (envName: _ref: "printf '%s=%s\\n' ${lib.escapeShellArg envName} \"$(tr -d '\\n' < ${lib.escapeShellArg (config.flake.lib.envSecretPath s.container_name envName)})\"") (s.envSecrets or {});
      in ''
        install -d -m 0700 ${lib.escapeShellArg envDir}
        umask 0077
        {
          ${lib.concatStringsSep "\n  " lines}
        } > ${lib.escapeShellArg envFile}
      '';
    in
      pkgs.writeShellScript "${projectName}-secret-env" (lib.concatStringsSep "\n" (map mkServiceBlock servicesWithEnvSecrets));

    processDockerServices = {
      name,
      services,
      caddy ? {},
    }: let
      servicesWithDomains = builtins.filter (s: (s.domains or []) != []) services;
      hasCaddyServices = servicesWithDomains != [];
      caddyNetworkName = "${name}-caddy-network";
      caddyEntries = builtins.listToAttrs (map (s: {
          name = s.container_name;
          value =
            {
              domains = s.domains;
              port = s.caddy_port;
              container_name = s.container_name;
            }
            // lib.optionalAttrs (s ? caddyRaw) {inherit (s) caddyRaw;};
        })
        servicesWithDomains);

      # globalConfig is consumed here (prepended to the Caddyfile) and extraNetworks is
      # appended to the caddy container's auto network (so a caddyRaw block can reverse_proxy
      # backends that live on an app network, e.g. matrix-rtc on synapse-net). The rest of
      # `caddy` (e.g. envSecrets, extraPorts, dataDir) is forwarded to the caddy factory.
      caddyGlobalConfig = caddy.globalConfig or "";
      caddyExtraNetworks = caddy.extraNetworks or [];
      caddyFactoryArgs = builtins.removeAttrs caddy ["globalConfig" "extraNetworks"];

      caddyfileContent = config.flake.lib.mkCaddyfile {
        entries = caddyEntries;
        globalConfig = caddyGlobalConfig;
      };
      caddyfilePath = builtins.toFile "Caddyfile" caddyfileContent;

      caddyServiceDef = config.flake.services.caddy ({
          networks = [caddyNetworkName] ++ caddyExtraNetworks;
          inherit caddyfilePath;
        }
        // caddyFactoryArgs);

      addCaddyNetwork = s:
        if (s.domains or []) != []
        then s // {networks = (s.networks or []) ++ [caddyNetworkName];}
        else s;

      addPostgresEnvAndSecrets = s:
        if s.postgres or false
        then let
          pgEnv = s.postgresEnv or {};
          passwordFileVar = pgEnv.passwordFile or "DATABASE_PASSWORD_FILE";
          passwordFilePrefix = pgEnv.passwordFilePrefix or "";
          hostVar = pgEnv.host or "DATABASE_HOST";
          portVar = pgEnv.port or "DATABASE_PORT";
          databaseVar = pgEnv.database or "DATABASE_NAME";
          userVar = pgEnv.user or "DATABASE_USER";
          databaseName = pgEnv.overrideDatabase or s.container_name;
          passwordPath = "/run/secrets/db_password";
        in
          s
          // {
            fileSecrets =
              (s.fileSecrets or {})
              // {
                ${passwordPath} = "op://${vaultId}/${databaseName} Postgres/password";
              };
            extra_hosts = (s.extra_hosts or []) ++ ["host.docker.internal:host-gateway"];
            environment =
              (s.environment or {})
              // {
                ${passwordFileVar} = "${passwordFilePrefix}${passwordPath}";
                ${hostVar} = "host.docker.internal";
                ${portVar} = "5432";
                ${databaseVar} = databaseName;
                ${userVar} = databaseName;
              };
          }
        else s;

      processedUserServices = map config.flake.lib.processServiceSecrets (map addPostgresEnvAndSecrets (map addCaddyNetwork services));
      allServicesList =
        processedUserServices
        ++ (lib.optional hasCaddyServices (config.flake.lib.processServiceSecrets caddyServiceDef));
    in {
      inherit caddyNetworkName hasCaddyServices allServicesList;
    };

    # Get a set of { domains, port, container_name } for services that have caddy_port set.
    # Domains should include their scheme (http:// or https://).
    getCaddyEntries = services:
      lib.filterAttrs (_: v: v.port != null) (
        lib.mapAttrs (_name: def: {
          domains = def.domains or [];
          port = def.caddy_port or null;
          container_name = def.container_name or null;
        })
        services
      );

    # entries: attrset keyed by container_name, each { domains, port, container_name, caddyRaw? }.
    # When an entry sets caddyRaw, that verbatim Caddyfile snippet is emitted instead of the
    # auto-generated reverse_proxy block (for path-based routing, CORS, custom matchers, etc.).
    # globalConfig, if non-empty, is prepended verbatim (e.g. a `{ layer4 { ... } }` block).
    mkCaddyfile = {
      entries,
      globalConfig ? "",
    }: let
      mkBlocks = _name: entry:
        if (entry.caddyRaw or null) != null
        then entry.caddyRaw
        else let
          httpsDomains = builtins.filter (d: lib.hasPrefix "https://" d) entry.domains;
          httpDomains = builtins.filter (d: !lib.hasPrefix "https://" d) entry.domains;
          reverseProxy = "reverse_proxy ${entry.container_name}:${toString entry.port}";
          httpsBlock = lib.optionalString (httpsDomains != []) ''
            ${lib.concatStringsSep ", " httpsDomains} {
                ${reverseProxy}

                tls {
                    dns cloudflare {env.CF_API_TOKEN}
                    resolvers 1.1.1.1
                }
            }
          '';
          httpBlock = lib.optionalString (httpDomains != []) ''
            ${lib.concatStringsSep ", " httpDomains} {
                ${reverseProxy}
            }
          '';
        in
          httpsBlock + httpBlock;
    in
      lib.concatStringsSep "\n" (
        lib.optional (globalConfig != "") globalConfig
        ++ lib.attrValues (lib.mapAttrs mkBlocks entries)
      );

    # Factory that returns a NixOS module setting host.caddyDomains and
    # virtualisation.arion.projects from a list of services.
    # The project name defaults to the host's networking.hostName.
    #
    # Services with postgres = true automatically get:
    #   - DATABASE_PASSWORD_FILE env var pointing to an opnix-managed secret file
    #   - DATABASE_HOST, DATABASE_PORT, DATABASE_NAME, DATABASE_USER env vars
    #   - extra_hosts entry for host.docker.internal
    #   - Generic fileSecret mounted at /run/secrets/db_password
    #
    # Customize env var names per service with postgresEnv:
    #   (myapp { postgres = true; postgresEnv.passwordFile = "MY_DB_PASS_FILE"; })
    #
    # Example:
    #   flake.modules.nixos.myhost = inputs.self.lib.mkHostServices {
    #     publicIPs = [ "1.2.3.4" "5.6.7.8" ];
    #     services = with inputs.self.services; [
    #       (jellyfin { domains = [ "https://stream.example.com" ]; })
    #     ];
    #   };
    mkHostServices = {
      services ? [],
      networks ? [],
      name ? null,
      publicIPs ? [],
      caddy ? {},
    }: {
      config,
      pkgs,
      ...
    }: let
      projectName =
        if name != null
        then name
        else config.networking.hostName;
      postgresServices = builtins.filter (s: s.postgres or false) services;
      hasPostgresServices = postgresServices != [];
      processed = flakeConfig.flake.lib.processDockerServices {
        inherit services caddy;
        name = projectName;
      };
      allSecretAttrs = flakeConfig.flake.lib.mkServiceSecretRegistrations processed.allServicesList;
      hasSecrets = allSecretAttrs != {};
      hasEnvSecrets = builtins.any (s: (s.envSecrets or {}) != {}) processed.allServicesList;
    in {
      imports = [inputs.self.modules.nixos.arion inputs.self.modules.nixos.opnix];

      host.caddyDomains = lib.concatMap (s: s.domains or []) services;
      host.publicIPs = publicIPs;
      postgres-puppy.databases = lib.concatMap (s:
        if s.postgres or false
        then [s.postgresEnv.overrideDatabase or s.container_name]
        else [])
      services;

      services.onepassword-secrets = lib.mkIf hasSecrets {
        enable = true;
        tokenFile = "/etc/op-token";
        secrets = allSecretAttrs;
      };

      systemd.services =
        lib.optionalAttrs hasPostgresServices {
          opnix-secrets = {
            after = ["postgres-puppy.service"];
            wants = ["postgres-puppy.service"];
          };
        }
        // lib.optionalAttrs hasEnvSecrets {
          "${projectName}-secret-env" = {
            description = "Prepare ${projectName} container secret env files";
            after = ["opnix-secrets.service"];
            requires = ["opnix-secrets.service"];
            before = ["${projectName}.service"];
            wantedBy = ["${projectName}.service"];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = flakeConfig.flake.lib.mkSecretEnvScript pkgs projectName processed.allServicesList;
            };
          };
        }
        // lib.optionalAttrs hasSecrets {
          ${projectName} = {
            after = ["opnix-secrets.service"] ++ lib.optional hasEnvSecrets "${projectName}-secret-env.service";
            wants = ["opnix-secrets.service"] ++ lib.optional hasEnvSecrets "${projectName}-secret-env.service";
          };
        };

      virtualisation.arion.projects.${projectName} = flakeConfig.flake.lib.mkArionProject {
        name = projectName;
        inherit networks services caddy processed;
      };
    };

    mkArionProject = {
      name,
      networks ? [],
      services,
      caddy ? {},
      processed ? null,
    }: let
      proc = if processed != null then processed else config.flake.lib.processDockerServices {inherit name services caddy;};

      arionServices = builtins.listToAttrs (map (s: {
          name = s.container_name;
          value = config.flake.lib.mkArionService s;
        })
        proc.allServicesList);

      userNetworks = builtins.listToAttrs (map (n: {
          name = n;
          value = {name = n;};
        })
        networks);
      caddyNetworks = lib.optionalAttrs proc.hasCaddyServices {
        ${proc.caddyNetworkName} = {name = proc.caddyNetworkName;};
      };
      allNetworks = userNetworks // caddyNetworks;
    in {
      serviceName = name;
      settings = {
        project.name = name;
        networks = allNetworks;
        services = arionServices;
      };
    };
  };
}
