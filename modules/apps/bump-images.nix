{...}: {
  perSystem = {pkgs, ...}: {
    packages.bump-images = pkgs.writeShellApplication {
      name = "bump-images";
      runtimeInputs = with pkgs; [bun go-containerregistry];
      text = ''exec bun ${./bump-images.ts} "$@"'';
    };
  };
}
