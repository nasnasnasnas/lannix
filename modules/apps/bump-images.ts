#!/usr/bin/env bun
// Bump image digests in modules/services/images.json.
//
// For each entry, resolves the current index digest via `crane digest`.
// Self-hosted git.szpunar.cloud images authenticate per-owner: the owner is
// extracted from the path (git.szpunar.cloud/<owner>/<repo>) and the token is
// read from REGISTRY_TOKEN_<OWNER_UPPER>. When a token is present, a temporary
// DOCKER_CONFIG dir is created with an auths entry for that owner, and crane
// is spawned with DOCKER_CONFIG pointed at it. When no token is set, crane
// runs anonymous (current behaviour — all images are public today).
//
// Resilient: per-image failures are collected and the loop continues; exit
// non-zero only after attempting all images. Prints machine-parseable
// CHANGED\t<key>\t<oldDigest>\t<newDigest> lines for the workflow to split
// into per-image PRs.

import { mkdtempSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

// Resolve images.json relative to CWD (repo root when run via `nix run`).
// The script itself lives in the Nix store, so import.meta.url can't find it.
const pinsPath = resolve(process.argv[2] || "modules/services/images.json");
const pins = await Bun.file(pinsPath).json();

const selfHosted = "git.szpunar.cloud";

const ownerToken = (owner: string): string | null => {
  const v = process.env[`REGISTRY_TOKEN_${owner.toUpperCase()}`];
  return v && v.length > 0 ? v : null;
};

// Create a temporary DOCKER_CONFIG for a specific owner's token.
// crane reads DOCKER_CONFIG (falling back to ~/.docker) for registry auth.
// docker config auths is keyed by host, so we can only hold one owner's
// token per config — hence per-spawn temp dirs.
const dockerConfigFor = (owner: string, token: string): string => {
  const dir = mkdtempSync(join(tmpdir(), "bump-images-docker-"));
  const auth = Buffer.from(`${owner}:${token}`).toString("base64");
  writeFileSync(join(dir, "config.json"), JSON.stringify({
    auths: { [selfHosted]: { auth } },
  }));
  return dir;
};

// Fetch OCI labels for a specific digest via `crane config`.
// Returns null if the image/config is unavailable (e.g. old digest GC'd).
const getLabels = (name: string, digest: string, env?: Record<string, string>): Record<string, string> | null => {
  const r = Bun.spawnSync(["crane", "config", `${name}@${digest}`], { env, timeout: 30000 });
  if (r.exitCode !== 0) return null;
  try {
    const config = JSON.parse(r.stdout.toString());
    return config?.config?.Labels ?? null;
  } catch {
    return null;
  }
};

// Format a markdown PR body with image metadata (version, build date, source).
const formatBody = (
  key: string, oldDigest: string, newDigest: string,
  oldLabels: Record<string, string> | null,
  newLabels: Record<string, string> | null,
): string => {
  const lines: string[] = [`Bumps \`${key}\` digest.`, "", `\`${oldDigest}\` → \`${newDigest}\``, ""];

  if (newLabels) {
    const version = newLabels["org.opencontainers.image.version"];
    const created = newLabels["org.opencontainers.image.created"];
    const source = newLabels["org.opencontainers.image.source"];
    const revision = newLabels["org.opencontainers.image.revision"];
    const desc = newLabels["org.opencontainers.image.description"];
    const url = newLabels["org.opencontainers.image.url"];

    const info: string[] = [];
    if (version) {
      const oldVersion = oldLabels?.["org.opencontainers.image.version"];
      info.push(`**Version:** ${oldVersion && oldVersion !== version ? `${oldVersion} → ` : ""}${version}`);
    }
    if (created) info.push(`**Built:** ${created}`);
    if (source) info.push(`**Source:** ${source}`);
    if (revision) {
      const baseUrl = source?.replace(/\.git$/, "").replace(/\/tree\/.*/, "");
      if (baseUrl) {
        info.push(`**Revision:** [${revision.substring(0, 12)}](${baseUrl}/commit/${revision})`);
      } else {
        info.push(`**Revision:** ${revision.substring(0, 12)}`);
      }
    }
    if (desc) info.push(`**Description:** ${desc}`);
    if (url) info.push(`**URL:** ${url}`);

    // Changelog: compare old → new revision if both are available.
    // Works for GitHub, Gitea, Forgejo (all use /compare/<old>...<new>).
    const oldRevision = oldLabels?.["org.opencontainers.image.revision"];
    if (source && oldRevision && revision && oldRevision !== revision) {
      const baseUrl = source.replace(/\.git$/, "").replace(/\/tree\/.*/, "");
      lines.push(`### Changelog`, "", `[Compare ${oldRevision.substring(0, 12)}…${revision.substring(0, 12)}](${baseUrl}/compare/${oldRevision}...${revision})`, "");
    }

    if (info.length) {
      lines.push("### Image metadata", "", ...info, "");
    }
  }

  lines.push("_Automated by `bump-images` workflow._");
  return lines.join("\n");
};

const failures: string[] = [];
const changed: { key: string; oldDigest: string; newDigest: string; body: string }[] = [];

for (const [key, e] of Object.entries(pins) as [string, any][]) {
  const name = e.name ?? key;
  const ref = `${name}:${e.tag}`;

  // Per-owner auth for self-hosted registry.
  let env: Record<string, string> | undefined;
  let configDir: string | undefined;
  if (name.startsWith(`${selfHosted}/`)) {
    const owner = name.split("/")[1]; // git.szpunar.cloud/<owner>/...
    const tok = ownerToken(owner);
    if (tok) {
      configDir = dockerConfigFor(owner, tok);
      env = { ...process.env, DOCKER_CONFIG: configDir };
    }
  }

  const r = Bun.spawnSync(["crane", "digest", ref], { env });

  if (r.exitCode !== 0) {
    if (configDir) rmSync(configDir, { recursive: true, force: true });
    console.error(`digest failed for ${key}: ${r.stderr.toString().trim()}`);
    failures.push(key);
    continue;
  }
  const digest = r.stdout.toString().trim();
  if (digest && digest !== e.digest) {
    const oldLabels = e.digest ? getLabels(name, e.digest, env) : null;
    const newLabels = getLabels(name, digest, env);
    const body = formatBody(key, e.digest ?? "(new)", digest, oldLabels, newLabels);
    changed.push({ key, oldDigest: e.digest ?? "(new)", newDigest: digest, body });
    e.digest = digest;
  }

  if (configDir) rmSync(configDir, { recursive: true, force: true });
}

if (changed.length) {
  await Bun.write(pinsPath, JSON.stringify(pins, null, 2) + "\n");
  for (const c of changed) console.log(`CHANGED\t${c.key}\t${c.oldDigest}\t${c.newDigest}\t${JSON.stringify(c.body)}`);
}

if (failures.length) {
  console.error(`failed: ${failures.join(", ")}`);
  process.exit(1);
}
