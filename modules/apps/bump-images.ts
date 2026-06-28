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

const failures: string[] = [];
const changed: { key: string; oldDigest: string; newDigest: string }[] = [];

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
  if (configDir) rmSync(configDir, { recursive: true, force: true });

  if (r.exitCode !== 0) {
    console.error(`digest failed for ${key}: ${r.stderr.toString().trim()}`);
    failures.push(key);
    continue;
  }
  const digest = r.stdout.toString().trim();
  if (digest && digest !== e.digest) {
    changed.push({ key, oldDigest: e.digest ?? "(new)", newDigest: digest });
    e.digest = digest;
  }
}

if (changed.length) {
  await Bun.write(pinsPath, JSON.stringify(pins, null, 2) + "\n");
  for (const c of changed) console.log(`CHANGED\t${c.key}\t${c.oldDigest}\t${c.newDigest}`);
}

if (failures.length) {
  console.error(`failed: ${failures.join(", ")}`);
  process.exit(1);
}
