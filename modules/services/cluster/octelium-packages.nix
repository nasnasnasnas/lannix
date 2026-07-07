{...}: {
  perSystem = {
    pkgs,
    lib,
    system,
    ...
  }: let
    octeliumVersion = "0.37.0";
    cordiumVersion = "0.12.7";

    mkOcteliumCli = {
      pname,
      repo,
      version,
      hash,
    }:
      pkgs.stdenvNoCC.mkDerivation {
        inherit pname version;

        src = pkgs.fetchurl {
          url = "https://github.com/octelium/${repo}/releases/download/v${version}/${pname}-linux-amd64.tar.gz";
          inherit hash;
        };

        dontUnpack = true;

        installPhase = ''
          runHook preInstall
          tar -xzf $src
          install -Dm755 ${pname} $out/bin/${pname}
          runHook postInstall
        '';

        meta = {
          mainProgram = pname;
          platforms = ["x86_64-linux"];
        };
      };
  in
    lib.mkIf (system == "x86_64-linux") {
      packages = {
        octelium = mkOcteliumCli {
          pname = "octelium";
          repo = "octelium";
          version = octeliumVersion;
          hash = "sha256-oztIslqCCKrYd4rpEgnvt6dR6MW/eiLS8WfnrEn0SUA=";
        };
        octeliumctl = mkOcteliumCli {
          pname = "octeliumctl";
          repo = "octelium";
          version = octeliumVersion;
          hash = "sha256-qDbnsfFs/1VDADjSuW71CCOjsgXwbpR+eUM4V0dhDGQ=";
        };
        octops = mkOcteliumCli {
          pname = "octops";
          repo = "octelium";
          version = octeliumVersion;
          hash = "sha256-Is6KEWhTMjg+3dj26Jv3/lpD8bY6VHzKXXxuWrDrQX0=";
        };
        cordium = mkOcteliumCli {
          pname = "cordium";
          repo = "cordium";
          version = cordiumVersion;
          hash = "sha256-fFxbzENXuJLdnglGTvt3CGjjE42jp1B7kxottD9hCJg=";
        };
      };
    };
}
