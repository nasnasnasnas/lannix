{
  lib,
  fetchFromGitHub,
  fetchurl,
  fetchPypi,
  python3Packages,
  llvmPackages,
  openssl,
  libplist,
  ldc,
  dub,
  cargo,
  rustc,
  stdenv,
}:
let
  # Both upstream native loaders support these 64-bit Linux architectures.
  platforms = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  temariPlatform = if stdenv.hostPlatform.isAarch64 then "linux-arm64" else "linux-x86_64";

  temari = python3Packages.buildPythonPackage {
    pname = "temari";
    version = "0.2.0";
    pyproject = true;
    src = fetchPypi {
      pname = "temari";
      version = "0.2.0";
      hash = "sha256-sBu+zMIrAt6LXgE55ti3W40G+o1BvT0dRRt1Tnnokvo=";
    };
    build-system = with python3Packages; [
      setuptools
      wheel
    ];
    nativeBuildInputs = [
      cargo
      rustc
    ];

    # The sdist includes the complete, dependency-free Rust crate as well as
    # foreign prebuilt libraries. Compile our own library, entirely offline.
    postPatch = ''
      rm -rf temari/lib
    '';
    preBuild = ''
      export CARGO_HOME="$TMPDIR/cargo-home"
      cargo build --offline --release \
        --manifest-path temari/_src/Cargo.toml \
        --target-dir "$TMPDIR/temari-target" \
        --jobs "$NIX_BUILD_CORES"
      install -Dm755 "$TMPDIR/temari-target/release/libtemari.so" \
        temari/lib/${temariPlatform}/libtemari.so
    '';
    postInstall = ''
      rm -rf "$out/${python3Packages.python.sitePackages}/temari/_src"
    '';
    doCheck = false;
    pythonImportsCheck = [ "temari" ];
    meta = {
      description = "Native FairPlay sample decryption and Python bindings";
      homepage = "https://github.com/WorldObservationLog/Temari";
      license = lib.licenses.mit;
      inherit platforms;
    };
  };

  # Pinned Git LFS assets from Polyphony's matching Flatpak manifest.
  assetBase = "https://gitlab.gnome.org/jannuary/polyphony/-/raw/c703c030931ddb8c264b5d47e1430202cc1532dc";
  vendor = fetchurl {
    url = "${assetBase}/apple-music-vendor.tar.xz";
    hash = "sha256-+09RuOK7VZJdzIQco89Fuzd0jAtBuAzrkiP3RGUfWHg=";
  };
  dubDeps = fetchurl {
    url = "${assetBase}/dub-deps.tar.xz";
    hash = "sha256-EWNos0s47VPex+O8HYQmfxYjQGrj27A03DSWDmyPCUo=";
  };
in
python3Packages.buildPythonPackage {
  pname = "orchestrator";
  version = "0.1.0-unstable-2026-11-14";
  pyproject = true;
  src = fetchFromGitHub {
    owner = "jannuary";
    repo = "orchestrator";
    rev = "ef4d2d138c66d9f9f7b47e7522927a845089dacb";
    hash = "sha256-ZBx1ekXW83sjMi6j12nos+RpHc781569NLr7pmsD0RQ=";
  };
  build-system = [ python3Packages.setuptools ];
  dependencies = [
    python3Packages.m3u8
    temari
  ];
  nativeBuildInputs = [
    llvmPackages.clang
    python3Packages.pip
    ldc
    dub
  ];

  # The generated FairPlay C sources use Clang's -Oz optimization option.
  env.CC = "${llvmPackages.clang}/bin/clang";
  postPatch = ''
    substituteInPlace src/aes.py \
      --replace-fail 'ctypes.CDLL("libcrypto.so.3")' \
        'ctypes.CDLL("${lib.getLib openssl}/lib/libcrypto.so.3")'
    substituteInPlace src/source_package.py \
      --replace-fail 'REPOSITORY_ROOT / "apple-music-source"' \
        "Path(\"$out/share/orchestrator/apple-music-source\")"
    substituteInPlace server.py \
      --replace-fail 'Path(__file__).resolve().parent / "certs" / "fps-certificate.bin"' \
        "Path(\"$out/share/orchestrator/certs/fps-certificate.bin\")"
  '';
  preBuild = ''
    # Upstream caps parallelism at four: generated units are memory-intensive.
    export APPLE_MUSIC_BUILD_JOBS="$NIX_BUILD_CORES"
    if [ "$APPLE_MUSIC_BUILD_JOBS" -gt 4 ]; then
      export APPLE_MUSIC_BUILD_JOBS=4
    fi
    # Build the vendored package first, then reuse its native libraries when
    # building the R1 probe. Nothing needs a compiler or writable assets later.
    ${python3Packages.python.interpreter} -m pip wheel \
      --no-cache-dir --no-deps --no-index --no-build-isolation \
      --wheel-dir apple-music-source/dist ./apple-music-source
    ${python3Packages.python.interpreter} scripts/build_source_native.py

    # Build provisioning offline; never reuse the archive's foreign static libs.
    export DUB_HOME="$TMPDIR/dub-home"
    mkdir -p "$DUB_HOME"
    tar -xJf ${dubDeps} -C "$DUB_HOME"
    chmod -R u+w "$DUB_HOME"
    find "$DUB_HOME" -name '*.a' -delete
    provision=apple-music-source/src/apple_music_source/_native/auth/provision_loader
    find "$provision" -name '*.a' -delete
    DC=ldc2 dub build --build=release --force --skip-registry=all --root="$provision"
  '';
  postInstall = ''
    ${python3Packages.python.interpreter} -m pip install \
      --no-cache-dir --no-deps --no-index --no-compile \
      --target "$out/share/orchestrator/apple-music-source/src" \
      apple-music-source/dist/*.whl
    install -m755 apple-music-source/src/apple_music_source/_native/r1_probe.so \
      "$out/share/orchestrator/apple-music-source/src/apple_music_source/_native/r1_probe.so"
    install -Dm644 certs/fps-certificate.bin \
      "$out/share/orchestrator/certs/fps-certificate.bin"
    provision=src/apple_music_source/_native/auth/provision_loader
    install -Dm755 "apple-music-source/$provision/build/libams_provision.so" \
      "$out/share/orchestrator/apple-music-source/$provision/build/libams_provision.so"
    # Provision's D bindings dlopen OpenSSL and libplist by SONAME.
    patchelf --add-rpath "${
      lib.makeLibraryPath [
        openssl
        libplist
        ldc
      ]
    }" \
      "$out/share/orchestrator/apple-music-source/$provision/build/libams_provision.so"
    tar -xJf ${vendor} -C "$out/share/orchestrator/apple-music-source"
  '';
  doCheck = false;
  pythonImportsCheck = [
    "server"
    "src"
  ];
  passthru = { inherit temari; };
  meta = {
    description = "Apple Music playback service with native provisioning";
    homepage = "https://github.com/jannuary/orchestrator";
    license = with lib.licenses; [
      mit
      lgpl21Plus
      unfree
    ];
    inherit platforms;
  };
}
