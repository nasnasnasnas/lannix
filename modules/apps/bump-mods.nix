{...}: {
  perSystem = {pkgs, ...}: {
    packages.bump-mods = pkgs.writeShellApplication {
      name = "bump-mods";
      runtimeInputs = [pkgs.bun];
      text = ''exec bun ${./bump-mods.ts} "$@"'';
    };
  };
}
