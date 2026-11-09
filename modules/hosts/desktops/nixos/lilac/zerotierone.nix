{ inputs, ... }: {
  flake.modules.nixos.lilac-zerotierone = {
    services.zerotierone = {
      enable = true;
      joinNetworks = [
        "6ea302b9c73ef22b" # 151
      ];
    };
  };
}
