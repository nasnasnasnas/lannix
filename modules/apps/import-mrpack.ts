#!/usr/bin/env bun
// Import the server-side mods from a Modrinth .mrpack into minecraft-mods.json.
//
// Modrinth-hosted indexed files and embedded override jars are matched by their
// sha512 hashes so the normal updater can keep tracking them. Other indexed
// jars remain immutable `url` pins. Unmatched embedded jars are content-addressed
// and uploaded to the public lannix Backblaze B2 bucket.

import { basename, join, resolve } from "node:path";
import { tmpdir } from "node:os";
import { mkdtemp, rename, rm, unlink } from "node:fs/promises";

type SideSupport = "required" | "optional" | "unsupported";

type MrpackFile = {
  path: string;
  hashes: {
    sha1?: string;
    sha512?: string;
  };
  env?: {
    client?: SideSupport;
    server?: SideSupport;
  };
  downloads: string[];
  fileSize: number;
};

type MrpackIndex = {
  formatVersion: number;
  game: string;
  name: string;
  versionId: string;
  files: MrpackFile[];
  dependencies: Record<string, string>;
};

type ModrinthVersionFile = {
  hashes: {
    sha512?: string;
  };
  url: string;
  filename: string;
};

type ModrinthVersion = {
  id: string;
  project_id: string;
  version_number: string;
  version_type: "release" | "beta" | "alpha";
  loaders: string[];
  game_versions: string[];
  files: ModrinthVersionFile[];
};

type ModrinthProject = {
  id: string;
  slug: string;
};

type ImportFile = {
  path: string;
  filename: string;
  url?: string;
  sha1?: string;
  sha256?: string;
  sha512: string;
  hash: string;
  localPath?: string;
  embedded: boolean;
};

type ModPin = Record<string, unknown>;

type Pack = {
  loader: string;
  gameVersion: string;
  versionType: "release";
  mods: Record<string, ModPin>;
};
type B2Authorization = {
  authorizationToken: string;
  apiInfo: {
    storageApi: {
      apiUrl: string;
      downloadUrl: string;
      allowed?: {
        buckets?: {id: string; name: string | null}[] | null;
        capabilities?: string[];
      };
    };
  };
};

type B2UploadTarget = {
  authorizationToken: string;
  uploadUrl: string;
};

type B2Client = {
  authorizationToken: string;
  apiUrl: string;
  downloadUrl: string;
  uploadTarget?: B2UploadTarget;
};


const API = "https://api.modrinth.com/v2";
const UA = "LAN/lannix (git.szpunar.cloud/LAN/lannix)";
const LOADER_BY_DEPENDENCY: Record<string, string> = {
  neoforge: "neoforge",
  forge: "forge",
  "fabric-loader": "fabric",
  "quilt-loader": "quilt",
};
const BATCH_SIZE = 100;
const B2_BUCKET = "minecraft-mod-jars";
const B2_BUCKET_ID = "a04272758573c80c95f6071c";
const B2_APPLICATION_KEY_ID_REF =
  "op://Secrets/Minecraft Mod Jars Bucket/username";
const B2_APPLICATION_KEY_REF =
  "op://Secrets/Minecraft Mod Jars Bucket/credential";
const B2_PREFIX = "minecraft-mods";
const temporaryDirectories: string[] = [];

const usage = () => {
  console.error(
    "usage: import-mrpack [--force] <pack-name> <pack.mrpack> [minecraft-mods.json]",
  );
};

const fail = (message: string): never => {
  throw new Error(message);
};

const hasOwn = (value: object, key: string) =>
  Object.prototype.hasOwnProperty.call(value, key);

const unzip = async (
  archive: string,
  option: string,
  ...members: string[]
): Promise<string> => {
  const process = Bun.spawn(["unzip", option, archive, ...members], {
    stdout: "pipe",
    stderr: "pipe",
  });
  const [stdout, stderr, exitCode] = await Promise.all([
    new Response(process.stdout).text(),
    new Response(process.stderr).text(),
    process.exited,
  ]);
  if (exitCode !== 0)
    fail(`unzip failed (${exitCode}): ${stderr.trim() || "unknown error"}`);
  return stdout;
};

// Hash an embedded jar while streaming it from unzip into a temporary file.
// The extracted copy exists only long enough to resolve or upload the jar.
const hashArchiveMember = async (
  archive: string,
  member: string,
  destination: string,
) => {
  const process = Bun.spawn(["unzip", "-p", archive, member], {
    stdout: "pipe",
    stderr: "pipe",
  });
  const stderrPromise = new Response(process.stderr).text();
  const reader = process.stdout.getReader();
  const sha1 = new Bun.CryptoHasher("sha1");
  const sha256 = new Bun.CryptoHasher("sha256");
  const sha512 = new Bun.CryptoHasher("sha512");
  const output = Bun.file(destination).writer();
  const magic: number[] = [];
  let size = 0;

  try {
    while (true) {
      const {done, value} = await reader.read();
      if (done) break;
      sha1.update(value);
      sha256.update(value);
      sha512.update(value);
      output.write(value);
      size += value.byteLength;
      for (let index = 0; index < value.byteLength && magic.length < 2; index++)
        magic.push(value[index]);
    }
  } finally {
    await output.end();
  }

  const [stderr, exitCode] = await Promise.all([stderrPromise, process.exited]);
  if (exitCode !== 0)
    fail(
      `unzip failed for ${member} (${exitCode}): ${stderr.trim() || "unknown error"}`,
    );
  if (size < 1024 || magic[0] !== 0x50 || magic[1] !== 0x4b)
    fail(`${member}: embedded file is not a plausible jar (${size} bytes)`);

  return {
    sha1: sha1.digest("hex"),
    sha256: sha256.digest("hex"),
    sha512: sha512.digest("hex"),
  };
};

const api = async <T>(path: string, init: RequestInit = {}): Promise<T> => {
  const headers = new Headers(init.headers);
  headers.set("Accept", "application/json");
  headers.set("User-Agent", UA);
  if (init.body) headers.set("Content-Type", "application/json");

  const response = await fetch(`${API}${path}`, {...init, headers});
  if (!response.ok) {
    const detail = (await response.text()).replace(/\s+/g, " ").slice(0, 200);
    fail(`Modrinth ${path}: HTTP ${response.status}${detail ? `: ${detail}` : ""}`);
  }
  return (await response.json()) as T;
};
const authorizeB2 = async (): Promise<B2Client> => {
  const credentials: string[] = [];
  for (const [name, reference] of [
    ["application key ID", B2_APPLICATION_KEY_ID_REF],
    ["application key", B2_APPLICATION_KEY_REF],
  ]) {
    // Desktop-app integration is not reliable when multiple `op read`
    // processes race for the same socket, so read the two fields serially.
    const process = Bun.spawn(["op", "read", reference], {
      stdout: "pipe",
      stderr: "pipe",
    });
    const [stdout, stderr, exitCode] = await Promise.all([
      new Response(process.stdout).text(),
      new Response(process.stderr).text(),
      process.exited,
    ]);
    const secret = stdout.trim();
    if (exitCode !== 0 || !secret)
      fail(
        `could not read B2 ${name} from 1Password: ${stderr.trim() || `op exited ${exitCode}`}`,
      );
    credentials.push(secret);
  }
  const response = await fetch(
    "https://api.backblazeb2.com/b2api/v4/b2_authorize_account",
    {
      headers: {
        Accept: "application/json",
        Authorization: `Basic ${Buffer.from(credentials.join(":")).toString("base64")}`,
        "User-Agent": UA,
      },
    },
  );
  if (!response.ok) {
    const detail = (await response.text()).replace(/\s+/g, " ").slice(0, 200);
    fail(`Backblaze authorization: HTTP ${response.status}${detail ? `: ${detail}` : ""}`);
  }

  const authorization = (await response.json()) as B2Authorization;
  const storage = authorization.apiInfo?.storageApi;
  if (
    !authorization.authorizationToken ||
    !storage?.apiUrl ||
    !storage.downloadUrl
  )
    fail("Backblaze authorization returned incomplete storage API metadata");
  if (
    storage.allowed?.capabilities &&
    !storage.allowed.capabilities.includes("writeFiles")
  )
    fail("Backblaze application key does not have writeFiles capability");
  if (
    storage.allowed?.buckets?.length &&
    !storage.allowed.buckets.some((bucket) => bucket.id === B2_BUCKET_ID)
  )
    fail(`Backblaze application key does not allow bucket ${B2_BUCKET}`);

  return {
    authorizationToken: authorization.authorizationToken,
    apiUrl: storage.apiUrl,
    downloadUrl: storage.downloadUrl,
  };
};

const requestB2UploadTarget = async (
  client: B2Client,
): Promise<B2UploadTarget> => {
  const response = await fetch(
    `${client.apiUrl}/b2api/v4/b2_get_upload_url?bucketId=${B2_BUCKET_ID}`,
    {
      headers: {
        Accept: "application/json",
        Authorization: client.authorizationToken,
        "User-Agent": UA,
      },
    },
  );
  if (!response.ok) {
    const detail = (await response.text()).replace(/\s+/g, " ").slice(0, 200);
    fail(
      `Backblaze upload URL: HTTP ${response.status}${detail ? `: ${detail}` : ""}`,
    );
  }
  const target = (await response.json()) as B2UploadTarget;
  if (!target.uploadUrl || !target.authorizationToken)
    fail("Backblaze returned an incomplete upload target");
  return target;
};

const publishToB2 = async (files: ImportFile[]) => {
  const client = await authorizeB2();

  for (const file of files) {
    const localPath =
      file.localPath ?? fail(`${file.path}: no extracted file available for upload`);
    const sha1 = file.sha1 ?? fail(`${file.path}: no sha1 available for upload`);
    const sha256 =
      file.sha256 ?? fail(`${file.path}: no sha256 available for upload`);
    const objectName = `${B2_PREFIX}/${sha256}/${file.filename}`;
    const encodedName = objectName
      .split("/")
      .map((component) => encodeURIComponent(component))
      .join("/");
    const publicUrl = `${client.downloadUrl}/file/${B2_BUCKET}/${encodedName}`;
    const local = Bun.file(localPath);
    const existing = await fetch(publicUrl, {
      method: "HEAD",
      headers: {"User-Agent": UA},
    });

    if (existing.ok) {
      const remoteSha1 = existing.headers.get("x-bz-content-sha1");
      const remoteSize = existing.headers.get("content-length");
      if (remoteSha1 !== sha1 || remoteSize !== String(local.size))
        fail(`${file.path}: existing Backblaze object does not match local jar`);
      console.error(`reused ${publicUrl}`);
    } else if (existing.status === 404) {
      let uploaded = false;
      let lastFailure = "unknown upload failure";
      for (let attempt = 1; attempt <= 5; attempt++) {
        try {
          client.uploadTarget ??= await requestB2UploadTarget(client);
          const response = await fetch(client.uploadTarget.uploadUrl, {
            method: "POST",
            headers: {
              Authorization: client.uploadTarget.authorizationToken,
              "Content-Length": String(local.size),
              "Content-Type": "application/java-archive",
              "User-Agent": UA,
              "X-Bz-Content-Sha1": sha1,
              "X-Bz-File-Name": encodedName,
            },
            body: Bun.file(localPath),
          });
          if (response.ok) {
            const result = (await response.json()) as {
              contentLength?: number;
              contentSha1?: string;
              fileName?: string;
            };
            if (
              result.contentSha1 !== sha1 ||
              result.contentLength !== local.size ||
              result.fileName !== objectName
            )
              fail(`${file.path}: Backblaze upload response failed integrity checks`);
            uploaded = true;
            console.error(`uploaded ${publicUrl}`);
            break;
          }

          const detail = (await response.text()).replace(/\s+/g, " ").slice(0, 200);
          lastFailure = `HTTP ${response.status}${detail ? `: ${detail}` : ""}`;
          const retryable =
            response.status === 401 ||
            response.status === 408 ||
            response.status === 429 ||
            response.status >= 500;
          client.uploadTarget = undefined;
          if (!retryable) fail(`${file.path}: Backblaze upload: ${lastFailure}`);
        } catch (error) {
          client.uploadTarget = undefined;
          lastFailure = error instanceof Error ? error.message : String(error);
        }
        if (attempt < 5) await Bun.sleep(2 ** (attempt - 1) * 250);
      }
      if (!uploaded)
        fail(`${file.path}: Backblaze upload failed after 5 attempts: ${lastFailure}`);
    } else {
      const detail = (await existing.text()).replace(/\s+/g, " ").slice(0, 200);
      fail(
        `${file.path}: Backblaze object check: HTTP ${existing.status}${detail ? `: ${detail}` : ""}`,
      );
    }

    file.url = publicUrl;
    file.hash = `sha256-${Buffer.from(sha256, "hex").toString("base64")}`;
  }
};

const validDownload = (downloads: string[], path: string): string => {
  for (const candidate of downloads) {
    try {
      const url = new URL(candidate);
      if (url.protocol === "https:" || url.protocol === "http:") return candidate;
    } catch {
      // Try the next published mirror.
    }
  }
  return fail(`${path}: no HTTP(S) download URL`);
};

const normalizeSha512 = (hash: string | undefined, path: string): string => {
  const normalized = hash?.trim().toLowerCase();
  if (!normalized || !/^[0-9a-f]{128}$/.test(normalized))
    fail(`${path}: missing or invalid sha512 hash`);
  return normalized;
};


const modKey = (value: string): string => {
  let key = value
    .toLowerCase()
    .replace(/\.jar$/i, "")
    .replace(/[^a-z0-9._-]+/g, "-")
    .replace(/^-+|-+$/g, "");
  if (!key) key = "mod";
  if (["__proto__", "constructor", "prototype"].includes(key)) key = `mod-${key}`;
  return key;
};

const loaderFrom = (dependencies: Record<string, string>) => {
  const found = Object.entries(LOADER_BY_DEPENDENCY).filter(
    ([dependency]) => dependencies[dependency],
  );
  if (found.length !== 1) {
    const names = found.map(([dependency]) => dependency).join(", ") || "none";
    fail(`mrpack must declare exactly one supported loader; found ${names}`);
  }
  const [dependency, loader] = found[0];
  return {dependency, loader, version: dependencies[dependency]};
};

const readIndex = async (archive: string): Promise<MrpackIndex> => {
  const raw = await unzip(archive, "-p", "modrinth.index.json");
  try {
    return JSON.parse(raw) as MrpackIndex;
  } catch (error) {
    return fail(
      `invalid modrinth.index.json: ${error instanceof Error ? error.message : error}`,
    );
  }
};

const resolveVersions = async (hashes: string[]) => {
  const versions = new Map<string, ModrinthVersion>();
  for (let offset = 0; offset < hashes.length; offset += BATCH_SIZE) {
    const batch = hashes.slice(offset, offset + BATCH_SIZE);
    const resolved = await api<Record<string, ModrinthVersion>>("/version_files", {
      method: "POST",
      body: JSON.stringify({hashes: batch, algorithm: "sha512"}),
    });
    for (const [hash, version] of Object.entries(resolved))
      versions.set(hash.toLowerCase(), version);
  }
  return versions;
};

const resolveProjects = async (ids: string[]) => {
  const projects = new Map<string, ModrinthProject>();
  for (let offset = 0; offset < ids.length; offset += BATCH_SIZE) {
    const batch = ids.slice(offset, offset + BATCH_SIZE);
    const query = encodeURIComponent(JSON.stringify(batch));
    const resolved = await api<ModrinthProject[]>(`/projects?ids=${query}`);
    for (const project of resolved) projects.set(project.id, project);
  }
  return projects;
};

const main = async () => {
  const args = process.argv.slice(2);
  if (args.includes("--help")) {
    usage();
    return;
  }
  const force = args.includes("--force");
  const positional = args.filter((argument) => argument !== "--force");
  const [packName, archiveArg, pinsArg, ...extra] = positional;
  if (!packName || !archiveArg || extra.length) {
    usage();
    process.exit(1);
  }
  if (!/^[a-z0-9][a-z0-9._-]*$/.test(packName))
    fail("pack name must be lowercase and contain only letters, digits, '.', '_', or '-'");
  if (["__proto__", "constructor", "prototype"].includes(packName))
    fail(`reserved pack name: ${packName}`);

  const archive = resolve(archiveArg);
  const pinsPath = resolve(pinsArg || "modules/services/minecraft-mods.json");
  if (!(await Bun.file(archive).exists())) fail(`mrpack not found: ${archive}`);
  if (!(await Bun.file(pinsPath).exists())) fail(`manifest not found: ${pinsPath}`);

  const manifest = (await Bun.file(pinsPath).json()) as Record<string, unknown>;
  if (!manifest || Array.isArray(manifest) || typeof manifest !== "object")
    fail(`${pinsPath}: expected a JSON object`);
  const replacing = hasOwn(manifest, packName);
  if (replacing && !force)
    fail(`pack '${packName}' already exists in ${pinsPath}; use --force to replace it`);

  const index = await readIndex(archive);
  if (index.formatVersion !== 1)
    fail(`unsupported mrpack formatVersion ${index.formatVersion}; expected 1`);
  if (index.game !== "minecraft") fail(`unsupported mrpack game '${index.game}'`);
  if (!Array.isArray(index.files)) fail("mrpack index has no files array");
  if (!index.dependencies || typeof index.dependencies !== "object")
    fail("mrpack index has no dependencies object");

  const gameVersion = index.dependencies.minecraft;
  if (!gameVersion) fail("mrpack does not declare a Minecraft version");
  const loader = loaderFrom(index.dependencies);

  const archiveEntries = (await unzip(archive, "-Z1"))
    .split("\n")
    .filter(Boolean);
  const embeddedMods = archiveEntries.filter((path) =>
    /^(?:server-)?overrides\/mods\/.+\.jar$/i.test(path),
  );
  const embeddedModSet = new Set(embeddedMods);
  const overrideCount = archiveEntries.filter(
    (path) =>
      /^(?:server-)?overrides\//.test(path) &&
      !path.endsWith("/") &&
      !embeddedModSet.has(path),
  ).length;

  const files: ImportFile[] = [];
  let ignoredFiles = 0;
  let clientOnlyFiles = 0;
  const filenames = new Set<string>();
  const extractionDirectory = embeddedMods.length
    ? await mkdtemp(join(tmpdir(), "import-mrpack-"))
    : null;
  if (extractionDirectory) temporaryDirectories.push(extractionDirectory);
  for (const file of index.files) {
    if (!file.path.startsWith("mods/") || !file.path.toLowerCase().endsWith(".jar")) {
      ignoredFiles++;
      continue;
    }
    if (file.env?.server === "unsupported") {
      clientOnlyFiles++;
      continue;
    }

    const filename = basename(file.path);
    if (filenames.has(filename)) fail(`duplicate mod filename: ${filename}`);
    filenames.add(filename);
    const sha512 = normalizeSha512(file.hashes?.sha512, file.path);
    files.push({
      path: file.path,
      filename,
      url: validDownload(file.downloads ?? [], file.path),
      sha512,
      hash: `sha512-${Buffer.from(sha512, "hex").toString("base64")}`,
      embedded: false,
    });
  }
  for (const path of embeddedMods) {
    const filename = basename(path);
    if (filenames.has(filename)) fail(`duplicate mod filename: ${filename}`);
    filenames.add(filename);
    const localPath = join(
      extractionDirectory ?? fail("missing embedded jar extraction directory"),
      filename,
    );
    const hashes = await hashArchiveMember(archive, path, localPath);
    files.push({
      path,
      filename,
      sha1: hashes.sha1,
      sha256: hashes.sha256,
      sha512: hashes.sha512,
      hash: `sha512-${Buffer.from(hashes.sha512, "hex").toString("base64")}`,
      localPath,
      embedded: true,
    });
  }
  if (!files.length) fail("mrpack has no server-compatible mod jars");

  const versions = await resolveVersions([...new Set(files.map((file) => file.sha512))]);
  const unresolved: ImportFile[] = [];
  for (const file of files) {
    if (file.url) continue;
    const version = versions.get(file.sha512);
    const match =
      version &&
      Array.isArray(version.files) &&
      version.files.find(
        (candidate) =>
          candidate.hashes?.sha512?.toLowerCase() === file.sha512,
      );
    if (!match) {
      unresolved.push(file);
      continue;
    }
    file.url = validDownload([match.url], file.path);
  }
  if (unresolved.length) await publishToB2(unresolved);
  const projectIds = [
    ...new Set(
      [...versions.values()].map((version) => version.project_id).filter(Boolean),
    ),
  ];
  const projects = await resolveProjects(projectIds);

  const mods: Record<string, ModPin> = Object.create(null);
  const urlPins: string[] = [];
  for (const file of files) {
    const version = versions.get(file.sha512);
    const project = version && projects.get(version.project_id);
    const key = modKey(project?.slug ?? file.filename);
    if (hasOwn(mods, key))
      fail(`multiple mrpack files resolve to mod key '${key}'`);
    const url = file.url ?? fail(`${file.path}: no resolved download URL`);

    if (!version) {
      mods[key] = {
        source: "url",
        filename: file.filename,
        url,
        hash: file.hash,
      };
      urlPins.push(key);
      continue;
    }
    if (!version.id || !version.project_id || !version.version_number)
      fail(`${file.path}: incomplete Modrinth version metadata`);
    if (!Array.isArray(version.loaders) || !Array.isArray(version.game_versions))
      fail(`${file.path}: invalid Modrinth compatibility metadata`);

    mods[key] = {
      project: project?.slug ?? version.project_id,
      ...(version.version_type !== "release"
        ? {versionType: version.version_type}
        : {}),
      ...(!version.loaders.includes(loader.loader)
        ? {loaders: version.loaders}
        : {}),
      ...(!version.game_versions.includes(gameVersion)
        ? {gameVersions: version.game_versions}
        : {}),
      rev: version.id,
      version: version.version_number,
      filename: file.filename,
      url,
      hash: file.hash,
    };
  }

  const pack: Pack = {
    loader: loader.loader,
    gameVersion,
    versionType: "release",
    mods: Object.fromEntries(
      Object.entries(mods).sort(([left], [right]) => left.localeCompare(right)),
    ),
  };
  manifest[packName] = pack;

  const temporaryPath = `${pinsPath}.tmp-${process.pid}`;
  try {
    await Bun.write(temporaryPath, JSON.stringify(manifest, null, 2) + "\n");
    await rename(temporaryPath, pinsPath);
  } finally {
    await unlink(temporaryPath).catch(() => {});
  }

  console.log(
    `${replacing ? "UPDATED" : "ADDED"}\t${packName}\t${files.length}\t${loader.loader}\t${gameVersion}`,
  );
  console.error(
    `loader version ${loader.version} (${loader.dependency}); set loaderVersion in the host service`,
  );
  if (clientOnlyFiles)
    console.error(`skipped ${clientOnlyFiles} server-unsupported mod(s)`);
  if (ignoredFiles)
    console.error(`ignored ${ignoredFiles} indexed non-mod file(s)`);
  const modrinthEmbedded = embeddedMods.length - unresolved.length;
  if (modrinthEmbedded)
    console.error(
      `resolved ${modrinthEmbedded} embedded override mod(s) through Modrinth`,
    );
  if (unresolved.length)
    console.error(
      `published ${unresolved.length} embedded override mod(s) through Backblaze B2`,
    );
  if (overrideCount)
    console.error(
      `warning: ${overrideCount} override file(s) are not represented by minecraft-mods.json`,
    );
  if (urlPins.length)
    console.error(
      `pinned ${urlPins.length} non-Modrinth mod(s) as source=url: ${urlPins.join(", ")}`,
    );
};

await main()
  .catch((error) => {
    console.error(error instanceof Error ? error.message : error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await Promise.all(
      temporaryDirectories.map((directory) =>
        rm(directory, {recursive: true, force: true}),
      ),
    );
  });
