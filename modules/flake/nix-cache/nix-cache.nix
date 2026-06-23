{...}: {
  flake.modules.nixos.nix-cache = {...}: {
    nix.settings = {
      extra-substituters = ["https://attic.szpunar.cloud/lannix"];
      extra-trusted-public-keys = ["lannix:HJSvPD/avQkNYKVD6CCDlLB+oLU8N87pdRJA5HE+k/o="];
    };
  };
}
