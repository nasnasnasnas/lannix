#!/usr/bin/env bun
// Bump mod pins in modules/services/minecraft-mods.json.
//
// Sources, dispatched per mod via the "source" field:
//   modrinth   - Modrinth v2 API, by project slug or id
//   curseforge - CurseForge website API for discovery, Curse Maven for download
//   url        - hand-pinned; skipped entirely
// Neither source needs credentials.
//
// Every jar is downloaded and hashed to sha256 SRI here rather than reusing an
// API-published hash: Modrinth gives sha512, Curse Maven gives nothing. Hashing
// locally keeps one code path and one algorithm.
//
// Resilient: per-mod failures are collected and the loop continues; exit
// non-zero only after attempting all mods. Prints one machine-parseable
// CHANGED\t<pack>\t<changesJson> line per changed pack for the workflow to
// open one PR containing all of that pack's updates.

import { resolve } from "node:path";

// Resolve relative to CWD (repo root when run via `nix run`). The script itself
// lives in the Nix store, so import.meta.url can't find it.
const pinsPath = resolve(process.argv[2] || "modules/services/minecraft-mods.json");
const packs = await Bun.file(pinsPath).json();

const MODRINTH = "https://api.modrinth.com/v2";
// Undocumented endpoint used by the CurseForge website itself. No key required,
// but Cloudflare-fronted and liable to change without notice — every call site
// must degrade rather than block. See cfDiscover.
const CF_WEB = "https://www.curseforge.com/api/v1";
// Keyless Maven proxies for CurseForge artifacts, tried in order.
const CURSE_MAVEN = ["https://cursemaven.com", "https://curse.cleanroommc.com"];
const UA = "LAN/lannix (git.szpunar.cloud/LAN/lannix)";

// Stability tiers, shared ranking across both sources.
const RANK: Record<string, number> = { release: 3, beta: 2, alpha: 1 };
// CurseForge releaseType: 1 release, 2 beta, 3 alpha.
const CF_RANK: Record<number, number> = { 1: 3, 2: 2, 3: 1 };

const enc = (v: unknown) => encodeURIComponent(JSON.stringify(v));

// Curse Maven coordinate: curse.maven:<descriptor>-<projectid>:<fileid>, laid
// out as standard Maven. The descriptor is free-form and does not affect
// resolution, so the manifest key is used for readability.
const curseMavenUrls = (
  descriptor: string,
  modId: number,
  fileId: number,
): string[] => {
  const artifact = `${descriptor.replace(/[^A-Za-z0-9._-]/g, "-")}-${modId}`;
  return CURSE_MAVEN.map(
    (host) =>
      `${host}/curse/maven/${artifact}/${fileId}/${artifact}-${fileId}.jar`,
  );
};

// Last-resort CDN paths derivable from a file id. Only usable when the real
// filename is known, and only tried after both Curse Maven hosts have failed.
const derivedUrls = (fileId: number, fileName: string): string[] => {
  const hi = Math.floor(fileId / 1000);
  const lo = fileId % 1000;
  const name = encodeURIComponent(fileName);
  const tails = [
    ...new Set([
      `${hi}/${lo}/${name}`,
      `${hi}/${String(lo).padStart(3, "0")}/${name}`,
    ]),
  ];
  return [
    "https://mediafilez.forgecdn.net/files",
    "https://edge.forgecdn.net/files",
  ].flatMap((host) => tails.map((tail) => `${host}/${tail}`));
};

// Download the first URL that yields a plausible jar, and hash it.
//
// The validation is load-bearing: a Maven miss or a wrong CDN guess can return
// an HTML error page, and without this guard the updater would pin the sha256
// of that page and Nix would fetch it forever. Jars are zip archives, so
// require the PK magic bytes and a non-trivial size.
const grab = async (urls: string[]): Promise<{ url: string; hash: string }> => {
  const errs: string[] = [];
  for (const url of urls) {
    try {
      const r = await fetch(url, { headers: { "User-Agent": UA } });
      if (!r.ok) {
        errs.push(`${url} -> HTTP ${r.status}`);
        continue;
      }
      const buf = await r.arrayBuffer();
      const magic = new Uint8Array(buf.slice(0, 2));
      if (buf.byteLength < 1024 || magic[0] !== 0x50 || magic[1] !== 0x4b) {
        errs.push(`${url} -> not a jar (${buf.byteLength} bytes)`);
        continue;
      }
      const hash =
        "sha256-" +
        new Bun.CryptoHasher("sha256").update(buf).digest("base64");
      return { url, hash };
    } catch (e) {
      errs.push(`${url} -> ${e}`);
    }
  }
  throw new Error(`no usable download:\n    ${errs.join("\n    ")}`);
};

type Resolved = {
  rev: string; // stable unique id, used for change detection
  version: string; // human-readable, used in PR change tables
  filename: string;
  fileId?: number; // curseforge only; recorded so discovery can fail later
  candidates: string[]; // download URLs to try in order
};

const resolveModrinth = async (
  name: string,
  mod: any,
  pack: any,
): Promise<Resolved> => {
  const project = mod.project ?? name;
  const loaders = mod.loaders ?? [pack.loader];
  const gameVersions = mod.gameVersions ?? [pack.gameVersion];
  const floor = RANK[mod.versionType ?? pack.versionType ?? "release"];

  const r = await fetch(
    `${MODRINTH}/project/${project}/version?loaders=${enc(loaders)}&game_versions=${enc(gameVersions)}`,
    { headers: { "User-Agent": UA } },
  );
  if (!r.ok) throw new Error(`modrinth HTTP ${r.status}`);

  const latest = ((await r.json()) as any[])
    .filter((v) => (RANK[v.version_type] ?? 0) >= floor)
    .sort(
      (a, b) =>
        Date.parse(b.date_published) - Date.parse(a.date_published),
    )[0];
  if (!latest)
    throw new Error(
      `no ${loaders.join("/")} build for ${gameVersions.join("/")}`,
    );

  const file = latest.files.find((f: any) => f.primary) ?? latest.files[0];
  return {
    rev: latest.id,
    version: latest.version_number,
    filename: file.filename,
    candidates: [file.url],
  };
};

// Find the newest matching file id via the CurseForge website API.
//
// The website API reports game versions and loader as a flat array of strings
// (e.g. ["1.21.1", "NeoForge", "Server"]) rather than the numeric enum the
// official API uses, so filtering is done by string match.
const cfDiscover = async (mod: any, pack: any) => {
  const loaderName = String(mod.loaders?.[0] ?? pack.loader).toLowerCase();
  const gameVersion = String(mod.gameVersions?.[0] ?? pack.gameVersion);
  const floor = RANK[mod.versionType ?? pack.versionType ?? "release"];

  const r = await fetch(
    `${CF_WEB}/mods/${mod.modId}/files?pageIndex=0&pageSize=50&sort=dateCreated&sortDescending=true`,
    { headers: { "User-Agent": UA, Accept: "application/json" } },
  );
  if (!r.ok) throw new Error(`curseforge web API HTTP ${r.status}`);

  const files = ((await r.json()) as any).data;
  if (!Array.isArray(files))
    throw new Error("unexpected response shape from curseforge web API");

  const match = files
    .filter((f: any) => (CF_RANK[f.releaseType] ?? 0) >= floor)
    .filter(
      (f: any) =>
        Array.isArray(f.gameVersions) &&
        f.gameVersions.includes(gameVersion) &&
        f.gameVersions.some(
          (v: any) => String(v).toLowerCase() === loaderName,
        ),
    )
    .sort(
      (a: any, b: any) =>
        Date.parse(b.dateCreated ?? b.fileDate) -
        Date.parse(a.dateCreated ?? a.fileDate),
    )[0];
  if (!match)
    throw new Error(`no ${loaderName} build for ${gameVersion}`);

  return {
    fileId: match.id as number,
    fileName: match.fileName as string,
    displayName: match.displayName as string,
  };
};

const resolveCurseforge = async (
  name: string,
  mod: any,
  pack: any,
): Promise<Resolved> => {
  if (!mod.modId) throw new Error("curseforge source requires a numeric modId");

  let fileId: number | undefined = mod.fileId;
  let fileName: string | undefined = mod.filename;
  let version: string | undefined = mod.version;

  if (!mod.pinned) {
    try {
      const discovered = await cfDiscover(mod, pack);
      fileId = discovered.fileId;
      fileName = discovered.fileName;
      version = discovered.displayName ?? discovered.fileName;
    } catch (e) {
      // Degrade rather than block: the website API is undocumented and may
      // start refusing CI traffic. A previously recorded fileId still resolves.
      if (!fileId) throw e;
      console.error(
        `  discovery failed (${e}); falling back to pinned fileId ${fileId}`,
      );
    }
  }
  if (!fileId)
    throw new Error(
      "no fileId: discovery unavailable and none recorded in the manifest",
    );

  const descriptor = name.replace(/[^A-Za-z0-9._-]/g, "-");
  return {
    rev: String(fileId),
    version: version ?? String(fileId),
    // Curse Maven serves the artifact under its Maven name; the real filename
    // is preferred when known. Mod loaders scan the directory and do not care
    // about the name, only the .jar extension.
    filename: fileName ?? `${descriptor}-${mod.modId}-${fileId}.jar`,
    fileId,
    candidates: [
      ...curseMavenUrls(descriptor, mod.modId, fileId),
      ...(fileName ? derivedUrls(fileId, fileName) : []),
    ],
  };
};

type Change = { mod: string; old: string; new: string };

const failures: string[] = [];
const changed = new Map<string, Change[]>();

// Optional single-pack filter, mirroring BUMP_ONLY in bump-images.
const only = process.env.BUMP_ONLY?.trim() || null;
if (only && !(only in packs)) {
  console.error(`BUMP_ONLY=${only} not found in ${pinsPath}`);
  process.exit(1);
}

for (const [packName, pack] of Object.entries(packs) as [string, any][]) {
  if (only && packName !== only) continue;

  for (const [modName, mod] of Object.entries(pack.mods) as [string, any][]) {
    const key = `${packName}/${modName}`;
    const source = mod.source ?? "modrinth";
    if (source === "url") continue;
    // pinned = don't look for anything newer. Still resolved once, so a
    // hand-set fileId can have its url + hash filled in on first run.
    if (mod.pinned && mod.url && mod.hash) continue;

    try {
      const res =
        source === "curseforge"
          ? await resolveCurseforge(modName, mod, pack)
          : await resolveModrinth(modName, mod, pack);

      // Skip the download entirely when nothing moved.
      if (mod.rev === res.rev && mod.hash) continue;

      const { url, hash } = await grab(res.candidates);

      const old = mod.version ?? "(new)";
      Object.assign(mod, {
        rev: res.rev,
        version: res.version,
        filename: res.filename,
        url,
        hash,
        ...(res.fileId ? { fileId: res.fileId } : {}),
      });
      let packChanges = changed.get(packName);
      if (!packChanges) {
        packChanges = [];
        changed.set(packName, packChanges);
      }
      packChanges.push({ mod: modName, old, new: res.version });
    } catch (e) {
      console.error(`${key}: ${e instanceof Error ? e.message : e}`);
      failures.push(key);
    }
  }
}

if (changed.size) {
  await Bun.write(pinsPath, JSON.stringify(packs, null, 2) + "\n");
  for (const [packName, changes] of changed)
    console.log(`CHANGED\t${packName}\t${JSON.stringify(changes)}`);
}

if (failures.length) {
  console.error(`failed: ${failures.join(", ")}`);
  process.exit(1);
}
