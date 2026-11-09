{ inputs, ... }: {
  flake.modules.nixos.lilac = {
    imports = with inputs.self.modules.nixos; [
      home-manager
      leah
      leah-desktop
      lilac-hardware
      lilac-system
      lilac-networking
      lilac-desktop
      lilac-easyeffects
      lilac-nirinit
      lilac-tern
      lilac-udev
      lilac-umbriel
      lilac-zerotierone
    ];
    home-manager.users.leah.imports = [ inputs.self.modules.homeManager.leah-lilac ];
    system.stateVersion = "25.05";
  };
}
