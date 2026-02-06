{...}: {
  flake.modules.nixos.host-dns = {lib, ...}: {
    options.host = {
      publicIP = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Public IP address for this host, used for DNS A record generation.";
      };
      caddyDomains = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Caddy domain URLs served by this host. Used for automatic DNS A record generation.";
      };
    };
  };
}
