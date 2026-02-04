{ ... }:
{
  perSystem = { config, ... }: {
    apps.pulumi-dns-gen = {
      type = "app";
      program = "${config.packages.pulumi-dns-gen}/bin/pulumi-dns-gen";
    };
  };
}
