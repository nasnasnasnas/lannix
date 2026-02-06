{...}: {
  flake.modules.nixos.host-dns = {lib, ...}: {
    options.host = {
      publicIPs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Public IP addresses for this host, used for DNS A record generation. Each Caddy domain gets an A record per IP.";
      };
      caddyDomains = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Caddy domain URLs served by this host. Used for automatic DNS A record generation.";
      };
    };
  };
}
