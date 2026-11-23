#!/usr/bin/env node
import { spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import { EventEmitter, on } from 'node:events';
import { createReadStream } from 'node:fs';
import { copyFile, mkdir, mkdtemp, rename, rm } from 'node:fs/promises';
import { homedir, tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { backup, DatabaseSync } from 'node:sqlite';

const origin = 'https://build.stencil.so';
const listing = `${origin}/api/products/tern/builds`;
const usage = 'Usage: ./download-tern.mjs [output-directory (default: ~/Downloads)]';

async function snapshotSession(profile) {
  const helium = join(process.env.XDG_CONFIG_HOME || join(homedir(), '.config'), 'net.imput.helium');
  const cookies = 'Default/Cookies';
  const source = new DatabaseSync(join(helium, cookies), { readOnly: true });
  try {
    await mkdir(dirname(join(profile, cookies)), { recursive: true });
    await backup(source, join(profile, cookies));
  } finally {
    source.close();
  }
  const snapshot = new DatabaseSync(join(profile, cookies));
  try {
    snapshot.exec(`PRAGMA secure_delete = ON;
      DELETE FROM cookies WHERE host_key NOT IN ('.stencil.so', '.build.stencil.so', 'build.stencil.so')
        OR name != '__Secure-stencil_session';`);
    if (!snapshot.prepare('SELECT 1 FROM cookies').get()) {
      throw new Error(`Sign in to ${origin} in Helium’s Default profile first.`);
    }
  } finally {
    snapshot.close();
  }
  await copyFile(join(helium, 'Local State'), join(profile, 'Local State'));
}

async function withHelium(profile, signal, run) {
  // CDP uses private pipes. Helium handles its own keyring and HTTPS cookies.
  const browser = spawn('helium', [
    '--headless=new', '--remote-debugging-pipe', '--password-store=gnome-libsecret',
    '--disable-background-networking', '--no-first-run', `--user-data-dir=${profile}`, 'about:blank',
  ], { stdio: ['ignore', 'ignore', 'ignore', 'pipe', 'pipe'] });
  const exited = new Promise(resolve => browser.once('close', resolve));
  const disconnected = new AbortController();
  browser.once('error', error => disconnected.abort(error));
  browser.once('close', () => disconnected.abort(new Error('Helium closed unexpectedly')));
  const [input, output] = browser.stdio.slice(3);
  input.on('error', error => disconnected.abort(error));
  output.on('error', error => disconnected.abort(error));
  signal = AbortSignal.any([signal, disconnected.signal]);
  const messages = new EventEmitter();
  let partial = '';
  output.setEncoding('utf8').on('data', chunk => {
    const frames = (partial + chunk).split('\0');
    partial = frames.pop();
    for (const frame of frames) messages.emit('message', JSON.parse(frame));
  });

  const events = () => on(messages, 'message', { signal });
  let nextId = 0;
  async function send(method, params = {}, sessionId) {
    const id = ++nextId;
    const replies = events();
    try {
      input.write(JSON.stringify({ id, method, params, sessionId }) + '\0');
      for await (const [reply] of replies) {
        if (reply.id !== id) continue;
        if (reply.error) throw new Error(`Helium rejected ${method}`);
        return reply.result;
      }
    } finally {
      await replies.return();
    }
  }

  try {
    return await run(send, events);
  } finally {
    browser.kill();
    await exited;
  }
}

async function latestRelease(send, events, page) {
  await page('Page.enable');
  await page('Page.setLifecycleEventsEnabled', { enabled: true });
  const navigation = events();
  try {
    const { loaderId, errorText } = await page('Page.navigate', { url: listing });
    if (!loaderId || errorText) throw new Error('Could not open the Stencil build listing');
    for await (const [{ method, params }] of navigation) {
      if (method === 'Page.lifecycleEvent' && params.loaderId === loaderId && params.name === 'DOMContentLoaded') break;
    }
  } finally {
    await navigation.return();
  }
  const { result } = await page('Runtime.evaluate', {
    expression: 'location.href === ' + JSON.stringify(listing) + ' ? document.body.textContent : null',
    returnByValue: true,
  });
  let builds;
  try {
    builds = JSON.parse(result.value)?.builds;
  } catch {
    // Signed-out requests can return a login page rather than JSON.
  }
  if (!Array.isArray(builds)) throw new Error(`Could not read the build listing. Check that you’re signed in to ${origin} in Helium.`);

  let latest;
  for (const build of builds) {
    const file = build.files.find(file => file.platform === 'linux' && file.arch === 'x86_64' && file.name.endsWith('.tar.gz'));
    const published = Date.parse(build.published_at);
    if (file && Number.isFinite(published) && (!latest || published > latest.published)) {
      latest = { file, published, version: build.version };
    }
  }
  if (!latest) throw new Error('No published Linux x86_64 Tern archive found');
  const { file, version } = latest;
  const url = new URL(file.url, origin);
  if (!/^\d+\.\d+\.\d+(?:[-+][\w.-]+)?$/.test(version) || file.name !== `Tern-${version}-linux-x86_64.tar.gz`
      || !/^[0-9a-f]{64}$/.test(file.sha256) || url.origin !== origin || url.username || url.password) {
    throw new Error('Unexpected Tern archive metadata from Stencil');
  }
  return { version, name: file.name, sha256: file.sha256, url: url.href };
}

async function download(profile, directory, signal) {
  return await withHelium(profile, signal, async (send, events) => {
    const { targetId } = await send('Target.createTarget', { url: 'about:blank' });
    const { sessionId } = await send('Target.attachToTarget', { targetId, flatten: true });
    const page = (method, params) => send(method, params, sessionId);
    const release = await latestRelease(send, events, page);
    console.error(`Downloading ${release.name}…`);
    await send('Browser.setDownloadBehavior', { behavior: 'allowAndName', downloadPath: directory, eventsEnabled: true });
    await page('Network.enable');
    const progress = events();
    try {
      const { frameId, isDownload, errorText } = await page('Page.navigate', { url: release.url });
      let status;
      if (!isDownload && !errorText) {
        for await (const [{ method, params }] of progress) {
          if (method === 'Network.responseReceived' && params.frameId === frameId && params.type === 'Document') {
            status = params.response.status;
            break;
          }
        }
      }
      if (!isDownload) throw new Error(`Stencil did not return an archive download${errorText || status ? ` (${errorText || `HTTP ${status}`})` : ''}`);
      let guid;
      for await (const [{ method, params }] of progress) {
        if (method === 'Browser.downloadWillBegin' && params.frameId === frameId) guid = params.guid;
        if (method !== 'Browser.downloadProgress' || !guid || params.guid !== guid) continue;
        if (params.state === 'canceled') throw new Error('Helium could not finish downloading the archive');
        if (params.state === 'completed') return { ...release, path: join(directory, guid) };
      }
    } finally {
      await progress.return();
    }
  });
}

async function main() {
  const args = process.argv.slice(2);
  if (args[0] === '--help') return console.log(usage);
  if (args.length > 1 || args[0]?.startsWith('-')) throw new Error(usage);
  const directory = resolve(args[0] ?? join(homedir(), 'Downloads'));
  await mkdir(directory, { recursive: true });
  const temporary = await mkdtemp(join(directory, '.tern-download-'));
  let profile;
  const interrupted = new AbortController();
  for (const name of ['SIGINT', 'SIGTERM']) {
    process.once(name, () => interrupted.abort(new Error(`Interrupted by ${name}`)));
  }
  const signal = AbortSignal.any([interrupted.signal, AbortSignal.timeout(300_000)]);
  try {
    // The download can be in a synced folder; keep browser state out of it.
    profile = await mkdtemp(join(tmpdir(), 'tern-helium-'));
    await snapshotSession(profile);
    const archive = await download(profile, temporary, signal);
    const hash = createHash('sha256');
    for await (const chunk of createReadStream(archive.path, { signal })) hash.update(chunk);
    const digest = hash.digest();
    if (digest.toString('hex') !== archive.sha256) throw new Error('Downloaded archive does not match Stencil’s SHA-256');
    const path = join(directory, archive.name);
    await rename(archive.path, path);
    console.log(JSON.stringify({ version: archive.version, path, hash: `sha256-${digest.toString('base64')}` }));
  } finally {
    const cleanup = [rm(temporary, { recursive: true, force: true })];
    if (profile) cleanup.push(rm(profile, { recursive: true, force: true }));
    await Promise.all(cleanup);
  }
}

try {
  await main();
} catch (error) {
  console.error(`download-tern: ${error.message}`);
  process.exitCode = 1;
}
