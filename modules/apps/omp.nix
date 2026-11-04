{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    # Figma's remote MCP server only registers catalog clients by name, so omp
    # identifies as opencode during OAuth client registration (see the patch).
    packages.omp = inputs.omp.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      patches =
        (old.patches or [])
        ++ [
          ./omp-opencode-client.patch
          ./omp-compiled-code-skew.patch
        ];
    });
  };
}
