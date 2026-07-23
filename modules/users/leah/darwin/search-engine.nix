{inputs, ...}: let
  username = "leah";
in {
  flake.modules.homeManager."${username}-darwin" = {lib, ...}: {
      targets.darwin.search = "Ecosia";
  };
}
