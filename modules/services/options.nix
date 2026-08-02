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

    # Resolve an image key from images.json to a digest-pinned reference: "name:tag@sha256:…"
    image = key: let
      pins = lib.importJSON ./images.json;
      e = pins.${key} or (throw "image-pin: no entry for ${key}");
      name = e.name or key;
    in "${name}:${e.tag}@${e.digest}";

    # Convert a simplified service definition to Arion service format by removing meta keys and moving service.out to out.service.
    mkArionService = serviceDef: let
      metaKeys = ["caddy_port" "domains" "out" "postgres" "postgresEnv" "envSecrets" "fileSecrets" "caddyRaw" "pgUrlSpecs"];
      serviceAttrs = removeAttrs serviceDef metaKeys;
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
      pgUrlVars = map (u: u.var) (s.pgUrlSpecs or []);
      hasEnvSecrets = envSecrets != {};
      hasFileSecrets = fileSecrets != {};
      hasRuntimeEnv = hasEnvSecrets || (s ? pgUrlSpecs);
      # Connection-string vars assembled from pgUrlSpecs are also generated at runtime from
      # secret files; strip any static values for them from the container environment.
      environmentWithoutSecrets = builtins.removeAttrs (s.environment or {}) (envSecretNames ++ pgUrlVars);
      fileSecretVolumes = map (containerPath: "${config.flake.lib.fileSecretPath serviceName containerPath}:${containerPath}:ro") (builtins.attrNames fileSecrets);
    in
      s
      // lib.optionalAttrs hasRuntimeEnv {
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
            mode = "0444";
          };
        }) (s.envSecrets or {}))
      services;
      fileSecretAttrs = lib.concatMap (s:
        lib.mapAttrsToList (containerPath: ref: {
          name = mkSecretName s.container_name "file" containerPath;
          value = {
            reference = ref;
            path = config.flake.lib.fileSecretPath s.container_name containerPath;
            # 0444 so non-root container processes can read their bind-mounted config.
            mode = "0444";
          };
        }) (s.fileSecrets or {}))
      services;
    in
      builtins.listToAttrs (envSecretAttrs ++ fileSecretAttrs);

    mkSecretEnvScript = pkgs: projectName: services: let
      needsRuntimeEnv = s: (s.envSecrets or {}) != {} || (s ? pgUrlSpecs);
      servicesWithRuntimeEnv = builtins.filter needsRuntimeEnv services;
      mkServiceBlock = s: let
        envDir = "${config.flake.lib.secretBaseDir s.container_name}/env";
        envFile = config.flake.lib.envFilePath s.container_name;
        envSecretLines = lib.mapAttrsToList (envName: _ref: "printf '%s=%s\\n' ${lib.escapeShellArg envName} \"$(tr -d '\\n' < ${lib.escapeShellArg (config.flake.lib.envSecretPath s.container_name envName)})\"") (s.envSecrets or {});
        # Connection strings (pgUrlSpecs) are assembled here at runtime because the password
        # only exists as a secret file; it is CR/LF-stripped and URL-encoded via jq @uri since
        # postgres-puppy generates base64/symbol passwords with URL-reserved characters.
        urlLines = lib.concatMap (u: let
          # database and suffix are emitted only when non-null. Normalize any caller-supplied
          # leading slash so a non-null database always has exactly one path separator; suffix
          # is passed as a printf argument (never spliced into the format string) so its
          # %/=/& chars stay literal.
          stripLeadingSlashes = database:
            if lib.hasPrefix "/" database
            then stripLeadingSlashes (lib.removePrefix "/" database)
            else database;
          dbArg =
            if (u.database or null) == null
            then ""
            else "/${stripLeadingSlashes u.database}";
          suffixArg = if (u.suffix or null) == null then "" else u.suffix;
        in [
          "pgpass=$(tr -d '\\r\\n' < ${lib.escapeShellArg u.passwordHostPath}); pgenc=$(${pkgs.jq}/bin/jq -rn --arg p \"$pgpass\" '$p|@uri'); printf '%s=%s://%s:%s@%s:%s%s%s\\n' ${lib.escapeShellArg u.var} ${lib.escapeShellArg u.scheme} ${lib.escapeShellArg u.user} \"$pgenc\" ${lib.escapeShellArg u.host} ${lib.escapeShellArg u.port} ${lib.escapeShellArg dbArg} ${lib.escapeShellArg suffixArg}"
        ]) (s.pgUrlSpecs or []);
        lines = envSecretLines ++ urlLines;
      in ''
        install -d -m 0700 ${lib.escapeShellArg envDir}
        umask 0077
        {
          ${lib.concatStringsSep "\n  " lines}
        } > ${lib.escapeShellArg envFile}
      '';
    in
      pkgs.writeShellScript "${projectName}-secret-env" (lib.concatStringsSep "\n" (map mkServiceBlock servicesWithRuntimeEnv));

    # Auto-wire a dedicated (containerized) Postgres for services with postgres = true:
    #   - DATABASE_PASSWORD_FILE env var pointing to an opnix-managed secret file
    #   - DATABASE_HOST, DATABASE_PORT, DATABASE_NAME, DATABASE_USER env vars
    #   - extra_hosts entry for host.docker.internal
    #   - Generic fileSecret mounted at /run/secrets/db_password
    #   - Optionally a single connection-string env var via postgresEnv.url
    #     (e.g. DATABASE_URL); the password is URL-encoded and injected at runtime
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
        urlSpecs = lib.optional ((pgEnv.url or null) != null) {
          var = pgEnv.url;
          scheme = pgEnv.urlScheme or "postgres";
          user = databaseName;
          host = "host.docker.internal";
          port = "5432";
          database = databaseName;
          suffix = null;
          passwordHostPath = config.flake.lib.fileSecretPath s.container_name passwordPath;
        };
        urlAttrs = lib.optionalAttrs ((pgEnv.url or null) != null) {
          pgUrlSpecs = urlSpecs;
        };
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
        // urlAttrs
      else s;

    # Per-project service processing: network attachment (proxy members and caddyExtraBackends
    # join the host caddy network), postgres auto-wiring, and secret processing. Caddy
    # generation is NOT done here — it is host-level (mkCaddyProject).
    processProjectServices = {
      projectName,
      services,
      caddyNetworkName,
      caddyExtraBackends ? [],
    }: let
      addCaddyNetwork = s:
        if (s.domains or []) != [] || lib.elem s.container_name caddyExtraBackends
        then s // {networks = (s.networks or []) ++ [caddyNetworkName];}
        else s;
      processed = map config.flake.lib.processServiceSecrets (map config.flake.lib.addPostgresEnvAndSecrets (map addCaddyNetwork services));
      hasProxyMembers = builtins.any (s: lib.elem caddyNetworkName (s.networks or [])) processed;
    in {
      services = processed;
      inherit hasProxyMembers;
    };

    # Host-level Caddy project: builds the Caddyfile from every domain-bearing service on the
    # host and returns the caddy service def plus the external proxy network definition.
    mkCaddyProject = {
      hostName,
      allServices,
      caddy ? {},
    }: let
      caddyNetworkName = "${hostName}-caddy-network";
      servicesWithDomains = builtins.filter (s: (s.domains or []) != []) allServices;
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

      # globalConfig is consumed here (prepended to the Caddyfile). The rest of `caddy`
      # (e.g. envSecrets, extraPorts, dataDir) is forwarded to the caddy factory.
      caddyGlobalConfig = caddy.globalConfig or "";
      caddyFactoryArgs = builtins.removeAttrs caddy ["globalConfig"];

      caddyfileContent = config.flake.lib.mkCaddyfile {
        entries = caddyEntries;
        globalConfig = caddyGlobalConfig;
      };
      caddyfilePath = builtins.toFile "Caddyfile" caddyfileContent;

      caddyServiceDef = config.flake.services.caddy ({
          networks = [caddyNetworkName];
          inherit caddyfilePath;
        }
        // caddyFactoryArgs);
    in {
      serviceDef = config.flake.lib.processServiceSecrets caddyServiceDef;
      networks = {
        ${caddyNetworkName} = {
          name = caddyNetworkName;
          external = true;
        };
      };
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
    # virtualisation.arion.projects from an attrset of projects (one Arion project per
    # coherent dependency group, plus one centralized Caddy project per host).
    #
    # Each project is { services = [...]; networks ? []; } — `networks` are Compose-owned
    # (non-external). `externalNetworks` are host-scoped networks that are NOT Compose-owned
    # (created by the ${hostName}-docker-networks oneshot, e.g. magicbox-network).
    # `caddyExtraBackends` lists container_names that join the proxy network without domains
    # (e.g. a backend only reachable from Caddy via a caddyRaw block).
    #
    # Services with postgres = true automatically get:
    #   - DATABASE_PASSWORD_FILE env var pointing to an opnix-managed secret file
    #   - DATABASE_HOST, DATABASE_PORT, DATABASE_NAME, DATABASE_USER env vars
    #   - extra_hosts entry for host.docker.internal
    #   - Generic fileSecret mounted at /run/secrets/db_password
    #   - Optionally a single connection-string env var via postgresEnv.url
    #     (e.g. DATABASE_URL); the password is URL-encoded and injected at runtime
    #
    # Customize env var names per service with postgresEnv:
    #   (myapp { postgres = true; postgresEnv.passwordFile = "MY_DB_PASS_FILE"; })
    #   (myapp { postgres = true; postgresEnv.url = "DATABASE_URL"; postgresEnv.urlScheme = "postgresql"; })
    #
    # Example:
    #   flake.modules.nixos.myhost = inputs.self.lib.mkHostServices {
    #     publicIPs = [ "1.2.3.4" "5.6.7.8" ];
    #     projects = {
    #       web = { services = [ (jellyfin { domains = [ "https://stream.example.com" ]; }) ]; };
    #     };
    #   };
    mkHostServices = {
      projects ? {},
      externalNetworks ? [],
      publicIPs ? [],
      caddy ? {},
      caddyExtraBackends ? [],
    }: {
      config,
      pkgs,
      ...
    }: let
      hostName = config.networking.hostName;
      caddyNetworkName = "${hostName}-caddy-network";
      allProjects = lib.mapAttrsToList (projectKey: p: p // {inherit projectKey;}) projects;
      allServices = lib.concatMap (p: p.services) allProjects;
      allContainerNames = map (s: s.container_name) allServices;
      hasPostgresServices = builtins.any (s: s.postgres or false) allServices;

      # ---- validations (evaluation-time throws with the offending name) ----
      duplicateNames = names: let
        count = name: builtins.length (builtins.filter (candidate: candidate == name) names);
      in
        builtins.filter (name: count name > 1) (lib.unique names);
      duplicateContainerNames = duplicateNames allContainerNames;
      depNames = s: let
        d = s.depends_on or [];
      in
        if builtins.isList d then d else builtins.attrNames d;
      invalidDependsOn = lib.concatMap (p: let
          projectNames = map (s: s.container_name) p.services;
        in
          lib.concatMap (s:
            map (dep: "${s.container_name} -> ${dep}")
            (builtins.filter (dep: !(lib.elem dep projectNames)) (depNames s)))
          p.services)
      allProjects;
      invalidNetworks = lib.concatMap (p: let
          allowed = (p.networks or []) ++ externalNetworks ++ [caddyNetworkName];
        in
          lib.concatMap (s:
            map (n: "${s.container_name} -> ${n}")
            (builtins.filter (n: !(lib.elem n allowed)) (s.networks or [])))
          p.services)
      allProjects;
      emptyProjects = builtins.filter (p: p.services == []) allProjects;
      missingBackends = builtins.filter (n: !(lib.elem n allContainerNames)) caddyExtraBackends;
      projectNameFor = projectKey: "${hostName}-${projectKey}";
      projectHasRuntimeEnv = pp:
        builtins.any (s: (s.envSecrets or {}) != {} || (s ? pgUrlSpecs)) pp.processed.services;
      dockerNetworksUnitName = "${hostName}-docker-networks";
      # Project keys occupy both their Arion/systemd name and the derived
      # `<key>-secret-env` namespace. Reserve infrastructure names up front so
      # future secret additions cannot turn a previously valid topology into a
      # silent attrset overwrite.
      projectKeys = builtins.attrNames projects;
      generatedSystemdUnitNames =
        ["docker-networks" "caddy" "caddy-secret-env"]
        ++ projectKeys
        ++ map (projectKey: "${projectKey}-secret-env") projectKeys;
      generatedArionProjectNames = ["caddy"] ++ projectKeys;
      duplicateGeneratedSystemdUnitNames = duplicateNames generatedSystemdUnitNames;
      duplicateGeneratedArionProjectNames = duplicateNames generatedArionProjectNames;
      checkAll = let
        problems =
          lib.optional (duplicateContainerNames != []) "duplicate container_name(s): ${lib.concatStringsSep ", " duplicateContainerNames}"
          ++ lib.optional (invalidDependsOn != []) "depends_on target outside same project: ${lib.concatStringsSep ", " invalidDependsOn}"
          ++ lib.optional (invalidNetworks != []) "service references undeclared network(s): ${lib.concatStringsSep ", " invalidNetworks}"
          ++ lib.optional (emptyProjects != []) "empty project(s): ${lib.concatStringsSep ", " (map (p: p.projectKey) emptyProjects)}"
          ++ lib.optional (missingBackends != []) "caddyExtraBackends not a container_name: ${lib.concatStringsSep ", " missingBackends}"
          ++ lib.optional (duplicateGeneratedSystemdUnitNames != []) "generated systemd unit name collision(s): ${lib.concatStringsSep ", " duplicateGeneratedSystemdUnitNames}"
          ++ lib.optional (duplicateGeneratedArionProjectNames != []) "generated Arion project name collision(s): ${lib.concatStringsSep ", " duplicateGeneratedArionProjectNames}";
      in
        if problems == []
        then true
        else throw "mkHostServices: ${lib.concatStringsSep "; " problems}";

      # ---- per-project processing ----
      processedProjects = lib.mapAttrsToList (projectKey: p: {
          inherit projectKey;
          processed = flakeConfig.flake.lib.processProjectServices {
            projectName = projectNameFor projectKey;
            services = p.services;
            inherit caddyNetworkName caddyExtraBackends;
          };
        })
      projects;
      allProcessedServices = lib.concatMap (pp: pp.processed.services) processedProjects;

      # ---- host-wide aggregation (once) ----
      caddyProject = flakeConfig.flake.lib.mkCaddyProject {
        inherit hostName caddy;
        allServices = allProcessedServices;
      };
      allSecretAttrs = flakeConfig.flake.lib.mkServiceSecretRegistrations (allProcessedServices ++ [caddyProject.serviceDef]);
      hasSecrets = allSecretAttrs != {};

      # ---- systemd units ----
      dockerNetworksUnit = {
        ${dockerNetworksUnitName} = {
          description = "Create ${hostName} external Docker networks";
          after = ["docker.service"];
          requires = ["docker.service"];
          before = map (p: "${projectNameFor p.projectKey}.service") allProjects ++ ["${caddyUnitName}.service"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript dockerNetworksUnitName (lib.concatMapStringsSep "\n" (n: let
                name = lib.escapeShellArg n;
              in ''
                if ! ${pkgs.docker}/bin/docker network inspect ${name} >/dev/null 2>&1; then
                  if ${pkgs.docker}/bin/docker network inspect ${name} 2>&1 | ${pkgs.gnugrep}/bin/grep -q 'No such network'; then
                    ${pkgs.docker}/bin/docker network create ${name}
                  else
                    echo "docker network inspect ${name} failed unexpectedly" >&2
                    exit 1
                  fi
                fi
              '')
            ([caddyNetworkName] ++ externalNetworks));
          };
        };
      };
      projectUnits = lib.listToAttrs (map (pp: let
          projectName = projectNameFor pp.projectKey;
          hasRuntimeEnv = projectHasRuntimeEnv pp;
        in {
          name = projectName;
          value = {
            after = ["${hostName}-docker-networks.service"] ++ lib.optional hasSecrets "opnix-secrets.service" ++ lib.optional hasRuntimeEnv "${projectName}-secret-env.service";
            wants = ["${hostName}-docker-networks.service"] ++ lib.optional hasSecrets "opnix-secrets.service" ++ lib.optional hasRuntimeEnv "${projectName}-secret-env.service";
          };
        })
      processedProjects);
      projectSecretEnvUnits = lib.listToAttrs (lib.concatMap (pp: let
          projectName = projectNameFor pp.projectKey;
          hasRuntimeEnv = projectHasRuntimeEnv pp;
        in
          lib.optional hasRuntimeEnv {
            name = "${projectName}-secret-env";
            value = {
              description = "Prepare ${projectName} container secret env files";
              after = ["opnix-secrets.service"];
              requires = ["opnix-secrets.service"];
              before = ["${projectName}.service"];
              wantedBy = ["${projectName}.service"];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = flakeConfig.flake.lib.mkSecretEnvScript pkgs projectName pp.processed.services;
              };
            };
          })
      processedProjects);
      caddyUnitName = "${hostName}-caddy";
      caddyHasRuntimeEnv = (caddyProject.serviceDef.envSecrets or {}) != {} || (caddyProject.serviceDef ? pgUrlSpecs);
      caddyUnit = {
        ${caddyUnitName} = {
          after = ["${hostName}-docker-networks.service"] ++ lib.optional hasSecrets "opnix-secrets.service" ++ lib.optional caddyHasRuntimeEnv "${caddyUnitName}-secret-env.service";
          wants = ["${hostName}-docker-networks.service"] ++ lib.optional hasSecrets "opnix-secrets.service" ++ lib.optional caddyHasRuntimeEnv "${caddyUnitName}-secret-env.service";
        };
      };
      caddySecretEnvUnit = lib.optionalAttrs caddyHasRuntimeEnv {
        "${caddyUnitName}-secret-env" = {
          description = "Prepare ${caddyUnitName} container secret env files";
          after = ["opnix-secrets.service"];
          requires = ["opnix-secrets.service"];
          before = ["${caddyUnitName}.service"];
          wantedBy = ["${caddyUnitName}.service"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = flakeConfig.flake.lib.mkSecretEnvScript pkgs caddyUnitName [caddyProject.serviceDef];
          };
        };
      };
      opnixSecretsOrdering = lib.optionalAttrs hasPostgresServices {
        opnix-secrets = {
          after = ["postgres-puppy.service"];
          wants = ["postgres-puppy.service"];
        };
      };

      # ---- Arion projects ----
      caddyArionProjects = {
        ${caddyUnitName} = flakeConfig.flake.lib.mkArionProject {
          name = caddyUnitName;
          services = [caddyProject.serviceDef];
          networks = caddyProject.networks;
        };
      };
      projectArionProjects = lib.listToAttrs (map (pp: {
          name = projectNameFor pp.projectKey;
          value = flakeConfig.flake.lib.mkArionProject {
            name = projectNameFor pp.projectKey;
            services = pp.processed.services;
            networks = let
              projectNetworks = builtins.listToAttrs (map (n: {
                  name = n;
                  value = {name = n;};
                })
                (projects.${pp.projectKey}.networks or []));
              # Host-scoped external networks that services of THIS project reference must
              # be declared external: true so compose validates and never creates them.
              referencedExternalNetworks = builtins.listToAttrs (map (n: {
                  name = n;
                  value = {
                    name = n;
                    external = true;
                  };
                })
                (builtins.filter (n: lib.elem n (lib.concatMap (s: s.networks or []) pp.processed.services)) externalNetworks));
              caddyNetwork = lib.optionalAttrs pp.processed.hasProxyMembers {
                ${caddyNetworkName} = {
                  name = caddyNetworkName;
                  external = true;
                };
              };
            in
              projectNetworks // referencedExternalNetworks // caddyNetwork;
          };
        })
      processedProjects);
    in
      assert checkAll;
      {
        imports = [inputs.self.modules.nixos.arion inputs.self.modules.nixos.opnix];

        host.caddyDomains = lib.concatMap (s: s.domains or []) allServices;
        host.publicIPs = publicIPs;
        postgres-puppy.databases = lib.unique (lib.concatMap (s:
          if s.postgres or false
          then [s.postgresEnv.overrideDatabase or s.container_name]
          else [])
        allServices);

        services.onepassword-secrets = lib.mkIf hasSecrets {
          enable = true;
          tokenFile = "/etc/op-token";
          secrets = allSecretAttrs;
        };

        systemd.services =
          dockerNetworksUnit
          // projectUnits
          // caddyUnit
          // opnixSecretsOrdering
          // projectSecretEnvUnits
          // caddySecretEnvUnit;

        virtualisation.arion.projects =
          caddyArionProjects
          // projectArionProjects;
      };

    mkArionProject = {
      name,
      services,
      networks ? {},
    }: let
      arionServices = builtins.listToAttrs (map (s: {
          name = s.container_name;
          value = config.flake.lib.mkArionService s;
        })
        services);
    in {
      serviceName = name;
      settings = {
        project.name = name;
        inherit networks;
        services = arionServices;
      };
    };
  };
}
