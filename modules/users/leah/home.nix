{
  inputs,
  ...
}:
let
  username = "leah";
in
{
  flake.modules.homeManager."${username}" =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        default-settings
      ];
      home.username = "${username}";
      home.packages = with pkgs; [
        imagemagick
      ];
    };
}