{ inputs, ... }: {
  # Host-local files contribute directly to lilac; imports select shared features.
  flake.modules.nixos.lilac = {
    imports = with inputs.self.modules.nixos; [
      home-manager
      leah
      leah-desktop
    ];
    home-manager.users.leah.imports = [ inputs.self.modules.homeManager.leah-lilac ];
    system.stateVersion = "25.05";
  };
}
