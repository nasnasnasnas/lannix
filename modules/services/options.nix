{
  lib,
  config,
  ...
}: {
  options.flake.services = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = {};
    description = "Docker service factory functions. Each service is a function that takes parameters and returns a simplified service definition.";
  };

  config.flake.lib = {
    # Convert a simplified service definition to Arion service format by removing meta keys and moving service.out to out.service.
    mkArionService = serviceDef: let
      metaKeys = ["caddy_port" "domains" "out"];
      serviceAttrs = builtins.removeAttrs serviceDef metaKeys;
      outAttrs = serviceDef.out or {};
    in {
      service = serviceAttrs;
      out.service = outAttrs;
    };

    mkArionServices = services:
      lib.mapAttrs (_name: config.flake.lib.mkArionService) services;

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

    mkCaddyfile = entries: let
      mkBlocks = _name: entry: let
        httpsDomains = builtins.filter (d: lib.hasPrefix "https://" d) entry.domains;
        httpDomains = builtins.filter (d: lib.hasPrefix "http://" d) entry.domains;
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
      lib.concatStringsSep "\n" (lib.attrValues (lib.mapAttrs mkBlocks entries));

    # Create an Arion project from a name, list of networks, and list of instantiated service definitions.
    # Automatically adds a caddy service and caddy network if any services have domains defined.
    #
    # Example:
    #   virtualization.arion.projects.myproject = inputs.self.lib.mkArionProject {
    #     name = "myproject";
    #     networks = [ "myproject-network" ];
    #     services = [
    #       (inputs.self.services.jellyfin { domains = [ "https://stream.example.com" ]; })
    #       (inputs.self.services.sonarr { domains = [ "https://sonarr.example.com" ]; })
    #     ];
    #   }
    mkArionProject = {
      name,
      networks ? [],
      services,
    }: let
      servicesWithDomains = builtins.filter (s: (s.domains or []) != []) services;
      hasCaddyServices = servicesWithDomains != [];
      caddyNetworkName = "${name}-caddy-network";
      caddyEntries = builtins.listToAttrs (map (s: {
          name = s.container_name;
          value = {
            domains = s.domains;
            port = s.caddy_port;
            container_name = s.container_name;
          };
        })
        servicesWithDomains);

      caddyfileContent = config.flake.lib.mkCaddyfile caddyEntries;
      caddyfilePath = builtins.toFile "Caddyfile" caddyfileContent;

      caddyServiceDef = config.flake.services.caddy {
        networks = [caddyNetworkName];
        inherit caddyfilePath;
      };

      addCaddyNetwork = s:
        if (s.domains or []) != []
        then s // {networks = (s.networks or []) ++ [caddyNetworkName];}
        else s;

      processedServices = map addCaddyNetwork services;
      allServicesList = processedServices ++ (lib.optional hasCaddyServices caddyServiceDef);

      arionServices = builtins.listToAttrs (map (s: {
          name = s.container_name;
          value = config.flake.lib.mkArionService s;
        })
        allServicesList);

      userNetworks = builtins.listToAttrs (map (n: {
          name = n;
          value = {name = n;};
        })
        networks);
      caddyNetworks = lib.optionalAttrs hasCaddyServices {
        ${caddyNetworkName} = {name = caddyNetworkName;};
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
