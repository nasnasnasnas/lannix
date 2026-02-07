{
  inputs,
  self,
  ...
}:

let
  username = "leah";
in
{
  flake.modules.nixos."${username}" =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    {

      imports = with inputs.self.modules.nixos; [
        # nixos modules for leah
      ];

      home-manager.users."${username}" = {
        imports = [
          # home manager modules for leah (including home.nix right next to us)
          inputs.self.modules.homeManager."${username}"
        ];
      };

      users.users."${username}" = {
        isNormalUser = true;
        shell = pkgs.fish;
      };
      programs.fish.enable = true;
    };
}