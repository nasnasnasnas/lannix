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
    entries =
      lib.mapAttrsToList (_n: m: {
        inherit (m) filename;
        src = pkgs.fetchurl {
          name = m.filename;
          inherit (m) url hash;
        };
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
