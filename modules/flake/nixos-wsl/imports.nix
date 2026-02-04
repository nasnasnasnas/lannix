{
  inputs,
  ...
}:
{
  flake-file.inputs = {
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
  };

  # imports = [ inputs.nixos-wsl.flakeModules.nixos-wsl ];
}