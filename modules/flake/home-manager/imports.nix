{
  inputs,
  ...
}:
{
  # Manage a user environment using Nix
  # https://github.com/nix-community/home-manager

  flake-file.inputs = {
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  imports = [ 
    #inputs.home-manager.flakeModules.home-manager
    #inputs.home-manager-unstable.flakeModules.home-manager
  ];
}