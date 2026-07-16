{...}: let
  cache-settings = {
    nix.settings = {
      extra-substituters = ["https://attic.szpunar.cloud/lannix"];
      extra-trusted-public-keys = ["lannix:HJSvPD/avQkNYKVD6CCDlLB+oLU8N87pdRJA5HE+k/o="];
    };
  };
in {
  flake.modules.nixos.nix-cache = {...}: cache-settings;
  flake.modules.darwin.nix-cache = {...}: cache-settings;
}
