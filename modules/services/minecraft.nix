{
  config,
  lib,
  inputs,
  ...
}: let
  packs = lib.importJSON ./minecraft-mods.json;

  # cp, not symlinkJoin/linkFarm: Docker bind mounts don't resolve symlinks
  # that point back into /nix/store, and the container has no store mounted.
  mkModsDir = system: packName: pack: let
    pkgs = inputs.nixpkgs.legacyPackages.${system};
    # Caverns & Chasms 3.0.0 reads unloaded CLIENT config from creative-tab
    # builders on dedicated servers: https://github.com/team-abnormals/caverns-and-chasms/issues/294
    patchCavernsAndChasms = pkgs.writeText "patch-caverns-and-chasms.py" ''
      from pathlib import Path
      import re
      import sys
      from tempfile import NamedTemporaryFile
      from zipfile import ZipFile

      CLASS_PATH = "com/teamabnormals/caverns_and_chasms/core/other/CCCreativeTabs.class"
      # Preserve the original IFEQ and method length, but make both conditions
      # true. This leaves the class's stack-map offsets unchanged.
      CONFIG_READ = re.compile(
          rb"\xb2\x00\x5d\xb4..\xb6\x00\x69\xc0\x00\x6c\xb6\x00\x6e"
      )
      ALWAYS_TRUE = b"\x04" + (b"\x00" * 14)

      jar_path = Path(sys.argv[1])
      with NamedTemporaryFile(dir=jar_path.parent, delete=False) as temporary:
          temporary_path = Path(temporary.name)

      try:
          found_class = False
          with ZipFile(jar_path, "r") as source, ZipFile(temporary_path, "w") as target:
              for entry in source.infolist():
                  contents = source.read(entry.filename)
                  if entry.filename == CLASS_PATH:
                      found_class = True
                      contents, patches = CONFIG_READ.subn(ALWAYS_TRUE, contents)
                      if patches != 2:
                          raise RuntimeError(
                              f"expected 2 client-config reads in {CLASS_PATH}, found {patches}; "
                              "the upstream class changed"
                          )
                  target.writestr(entry, contents)

          if not found_class:
              raise RuntimeError(f"{CLASS_PATH} is missing from {jar_path}")
          temporary_path.replace(jar_path)
      except BaseException:
          temporary_path.unlink(missing_ok=True)
          raise
    '';
    patchers = {
      caverns-and-chasms-dedicated-config = src:
        pkgs.runCommand "caverns-and-chasms-dedicated-config.jar" {} ''
          cp ${src} "$out"
          chmod u+w "$out"
          ${pkgs.python3}/bin/python ${patchCavernsAndChasms} "$out"
        '';
    };
    applyPatch = src: patchName: let
      patcher =
        patchers.${patchName}
        or (throw "minecraft: unknown server patch '${patchName}'");
    in
      patcher src;
    entries =
      lib.mapAttrsToList (_n: m: let
        fetched = pkgs.fetchurl {
          name = m.filename;
          inherit (m) url hash;
        };
      in {
        inherit (m) filename;
        src = lib.foldl' applyPatch fetched (m.serverPatches or []);
      })
      pack.mods;
  in
    pkgs.runCommand "minecraft-mods-${packName}" {} ''
      mkdir -p "$out"
      ${lib.concatMapStringsSep "\n" (e: ''cp ${e.src} "$out"/${lib.escapeShellArg e.filename}'') entries}
    '';
in {
  flake.services.minecraft = {
    container_name ? "minecraft",
    image ? config.flake.lib.image "itzg/minecraft-server",
    restart ? "unless-stopped",
    networks ? [],
    dataDir,
    pack,
    port ? 25565,
    system ? "x86_64-linux",
    loaderVersion ? null,
    memory ? "6G",
    environment ? {},
    volumes ? [],
    depends_on ? [],
  }: let
    p =
      packs.${pack}
      or (throw "minecraft: no pack '${pack}' in minecraft-mods.json");
    loaderEnv = {
      neoforge = "NEOFORGE_VERSION";
      forge = "FORGE_VERSION";
      fabric = "FABRIC_LOADER_VERSION";
      quilt = "QUILT_LOADER_VERSION";
    };
  in {
    inherit container_name image restart networks depends_on;
    ports = ["${toString port}:25565"];
    environment =
      {
        EULA = "TRUE";
        TYPE = lib.toUpper p.loader;
        VERSION = p.gameVersion;
        MEMORY = memory;
        USE_MEOWICE_FLAGS = "true";
        TZ = "America/Indiana/Indianapolis";
      }
      // lib.optionalAttrs (loaderVersion != null) {
        ${loaderEnv.${p.loader}} = loaderVersion;
      }
      // environment;
    volumes =
      [
        "${dataDir}:/data"
        "${mkModsDir system pack p}:/mods:ro"
      ]
      ++ volumes;
    # Arion doesn't model these as first-class options, so use the raw escape hatch.
    out = {
      tty = true;
      stdin_open = true;
    };
  };
}
