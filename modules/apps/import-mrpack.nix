{...}: {
  perSystem = {pkgs, ...}: {
    packages.import-mrpack = pkgs.writeShellApplication {
      name = "import-mrpack";
      runtimeInputs = [pkgs.bun pkgs.unzip];
      text = ''exec bun ${./import-mrpack.ts} "$@"'';
    };
  };
}
