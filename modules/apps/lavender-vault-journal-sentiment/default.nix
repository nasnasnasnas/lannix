{inputs, ...}: {
  perSystem = {pkgs, ...}: let
    bun2nix = inputs.bun2nix.packages.${pkgs.system}.bun2nix;
  in {
    packages.lavender-vault-journal-sentiment = bun2nix.mkDerivation {
      pname = "lavender-vault-journal-sentiment";
      version = "0.1.0";
      src = ./.;
      module = "index.ts";
      # Bun's --bytecode compilation does not support top-level await, which
      # index.ts relies on. Disabling it keeps the standalone --compile output.
      bunCompileToBytecode = false;
      bunDeps = bun2nix.fetchBunDeps {
        bunNix = ./_bun.nix;
      };
    };
  };
}
