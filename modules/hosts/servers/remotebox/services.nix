{inputs, ...}: {
  flake.modules.nixos.remotebox = {...}: {
    imports = [
      inputs.self.modules.nixos.arion
    ];

    virtualisation.arion.projects.magicbox = inputs.self.lib.mkArionProject {
      name = "remotebox";
      networks = [];
      services = [
        (inputs.self.services.helloworld {domains = ["localhost"];})
      ];
    };
  };
}
