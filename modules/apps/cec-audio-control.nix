{...}: {
  perSystem = {
    pkgs,
    lib,
    ...
  }: {
    packages.cec-audio-control = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
      pname = "cec-audio-control";
      version = "0.1.0";
      src = pkgs.fetchFromGitLab {
        domain = "gitlab.steamos.cloud";
        owner = "holo";
        repo = "cec-audio-control";
        rev = "37f1f520c78790f3e9406b908e452c217c37788d";
        hash = "sha256-OJLeXAcJINr/OXPCy6WhDm0oYK26ncXec20smwuyoxc=";
      };
      cargoHash = "sha256-YDtAv24Vjg9Nc6IHYnmVFq2OjQtonOnbIXmKGOLVGNA=";

      nativeBuildInputs = [
        pkgs.pkg-config
      ];
    });
  };
}
