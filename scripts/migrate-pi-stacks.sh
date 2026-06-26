#!/usr/bin/env bash
#
# Migrate the Synapse/Matrix + Sharkey stacks from the Raspberry Pi to magicplank.
#
# This does two jobs, as separate subcommands so you can run/redo them independently:
#
#   secrets  - pull the live config/secret files off the Pi and load them into 1Password
#              (vault "Secrets") as the items the NixOS config references via opnix.
#   data     - rsync the stateful data (Postgres clusters, Synapse media_store, bridge
#              SQLite dbs, Sharkey files, Redis) from the Pi into magicplank's data dirs.
#   all      - secrets then data.
#
# The download in ~/Downloads/pi-stacks is INCOMPLETE (missing some bridge configs, plus a
# stale homeserver.db), so everything here is sourced from the live Pi over SSH.
#
# Docker bind-mount data on the Pi is owned by container UIDs / root (Postgres uid 70, Synapse
# 991, Redis 999, ...), unreadable to a normal login and re-creatable only by root. So this
# script uses sudo at both ends:
#   - reads on the Pi run as root (`sudo cat`, `--rsync-path="sudo rsync"`)
#   - the DATA rsync is executed ON magicplank, pulling straight from the Pi via your
#     forwarded ssh agent, with root on both ends and --numeric-ids — so the original UIDs are
#     preserved exactly (same container images => same UIDs, no guessing/chowning needed).
# These run over ssh with NO TTY, so sudo cannot prompt. Acquire privilege one of two ways
# (auto-detected from the ssh user; override per host with PI_SUDO=/MP_SUDO=):
#   - connect as root@<host>            -> no sudo used (recommended; magicplank allows root ssh)
#   - connect as a normal user          -> `sudo` is prefixed and must be PASSWORDLESS (NOPASSWD)
# magicplank must also be able to reach the Pi (set PI_FROM_MP if its address differs from there).
#
# Example (root both ends, simplest): PI=root@10.1.0.11 MP=root@magicplank ./migrate-pi-stacks.sh data
#
# Prereqs on the machine you run this from: ssh access (with agent, i.e. `ssh-add`) to both the
# Pi and magicplank, and `op` (1Password CLI) signed in. rsync / ssh / yq / jq are pulled in
# automatically via `nix shell` (see the re-exec below); `op` is expected to already be on PATH.
#
# Usage:
#   PI=pi@raspberrypi MP=magicbox@magicplank ./migrate-pi-stacks.sh all
#
# Override remote layout / behaviour with env vars (see the block below). Set DRY_RUN=1 to
# print what would happen without creating 1Password items or writing to magicplank.

# Re-exec inside a nix shell that provides the CLI tooling (yq = mikefarah/yq v4). This adds
# to PATH without clobbering it, so an already-set-up `op` (1Password CLI) still resolves.
if [ -z "${_MIGRATE_NIX_SHELL:-}" ]; then
  exec nix shell nixpkgs#bash nixpkgs#rsync nixpkgs#openssh nixpkgs#yq-go nixpkgs#jq \
    --command env _MIGRATE_NIX_SHELL=1 bash "$0" "$@"
fi

set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────────────────────────
PI="${PI:?set PI=user@pi-host}"                       # ssh target for the Raspberry Pi
MP="${MP:?set MP=user@magicplank}"                    # ssh target for magicplank
VAULT="${VAULT:-Secrets}"                              # 1Password vault

# Remote paths on the Pi (the stack directories that hold the docker bind-mounts).
PI_SYNAPSE="${PI_SYNAPSE:-/home/pi/stacks/synapse}"          # holds files/, schemas/, mautrix-*/
PI_SHARKEY="${PI_SHARKEY:-/home/pi/stacks/Sharkey}"          # holds .config/, files/, db/, redis/

# The Pi's ssh address *as seen from magicplank* (the data rsync runs on magicplank and pulls
# from here, authenticating with your forwarded agent). Defaults to $PI.
PI_FROM_MP="${PI_FROM_MP:-$PI}"

# Destination data dirs on magicplank (must match modules/.../magicplank/services.nix).
MP_DATA="${MP_DATA:-/home/magicbox/data}"

DRY_RUN="${DRY_RUN:-0}"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

# Reading the Pi's bind-mounts and writing magicplank's data dirs both need root. Privilege is
# acquired non-interactively (these run over ssh with no TTY, so sudo cannot prompt): connect as
# root@<host> and no sudo is used; otherwise we prefix `sudo`, which then REQUIRES passwordless
# sudo for that user. Auto-detected from the ssh target's user; override with PI_SUDO/MP_SUDO=""
# (root) or ="sudo".
_default_sudo() { case "$1" in root@*|root) echo "" ;; *) echo "sudo" ;; esac; }
PI_SUDO="${PI_SUDO-$(_default_sudo "$PI")}"
MP_SUDO="${MP_SUDO-$(_default_sudo "$MP")}"
# rsync-path run on the Pi end (root there too, so it can read the bind-mounts).
PI_RSYNC_PATH="${PI_SUDO:+sudo }rsync"

log()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!! \033[0m %s\n' "$*" >&2; }
run()  { if [ "$DRY_RUN" = 1 ]; then echo "DRY: $*"; else "$@"; fi; }

# Pull a (possibly root-owned) file from the Pi into the local staging dir (mode 600) via
# `sudo cat`. Returns non-zero (and warns) if the remote file does not exist, so callers can
# skip optional pieces gracefully.
pull() { # pull <remote-path> <local-name>
  local remote="$1" local_name="$2"
  if ssh "$PI" "$PI_SUDO test -f '$remote'"; then
    ( umask 077; ssh "$PI" "$PI_SUDO cat '$remote'" > "$STAGE/$local_name" )
    return 0
  fi
  warn "missing on Pi, skipping: $remote"
  return 1
}

# ── 1Password helpers ────────────────────────────────────────────────────────────────────
op_item_exists() { op item get "$1" --vault "$VAULT" >/dev/null 2>&1; }

# Create/replace a Secure Note holding a whole file's contents in the notesPlain field.
# Referenced from Nix as op://<VAULT>/<title>/notesPlain.
op_note_from_file() { # op_note_from_file <title> <local-file>
  local title="$1" file="$2"
  [ -f "$file" ] || { warn "no local file for note '$title' — skipping"; return 0; }
  if op_item_exists "$title"; then
    log "1Password note exists, updating: $title"
    run op item edit "$title" --vault "$VAULT" "notesPlain=$(cat "$file")" >/dev/null
  else
    log "1Password note create: $title"
    run op item create --category "Secure Note" --vault "$VAULT" \
      --title "$title" "notesPlain=$(cat "$file")" >/dev/null
  fi
}

# Create/replace a Password item (single `password` field).
op_password() { # op_password <title> <password>
  local title="$1" pw="$2"
  if op_item_exists "$title"; then
    log "1Password password exists, updating: $title"
    run op item edit "$title" --vault "$VAULT" "password=$pw" >/dev/null
  else
    log "1Password password create: $title"
    run op item create --category Password --vault "$VAULT" \
      --title "$title" "password=$pw" >/dev/null
  fi
}

# ── secrets ──────────────────────────────────────────────────────────────────────────────
do_secrets() {
  log "Loading secrets into 1Password vault '$VAULT'"

  # ---- Synapse: signing key + config-secrets fragment + DB password ----
  if pull "$PI_SYNAPSE/files/szp.lol.signing.key" signing.key; then
    op_note_from_file "Synapse Signing Key" "$STAGE/signing.key"
  fi

  if pull "$PI_SYNAPSE/files/homeserver.yaml" homeserver.full.yaml; then
    # Build the secrets-only fragment (owns the whole top-level keys Synapse merges shallowly).
    # Rewrite the DB host from the old compose name `db` to the new container `synapse-db`.
    yq '{
          "database": (.database | .args.host = "synapse-db"),
          "registration_shared_secret": .registration_shared_secret,
          "macaroon_secret_key": .macaroon_secret_key,
          "form_secret": .form_secret
        }' "$STAGE/homeserver.full.yaml" > "$STAGE/zz-secrets.yaml"
    op_note_from_file "Synapse Config Secrets" "$STAGE/zz-secrets.yaml"

    local syn_db_pass
    syn_db_pass="$(yq -r '.database.args.password' "$STAGE/homeserver.full.yaml")"
    op_password "Synapse DB" "$syn_db_pass"
  fi

  # ---- Bridges: registration.yaml (shared with Synapse) + config.yaml ----
  # heisenbridge.yaml is a single combined config+registration file.
  if pull "$PI_SYNAPSE/files/heisenbridge.yaml" heisenbridge.yaml; then
    op_note_from_file "Heisenbridge Registration" "$STAGE/heisenbridge.yaml"
  fi

  local bridge
  for bridge in telegram signal discord; do
    local title_cc
    case "$bridge" in
      telegram) title_cc="Telegram" ;;
      signal)   title_cc="Signal" ;;
      discord)  title_cc="Discord" ;;
    esac
    if pull "$PI_SYNAPSE/mautrix-$bridge/registration.yaml" "reg-$bridge.yaml"; then
      op_note_from_file "Mautrix $title_cc Registration" "$STAGE/reg-$bridge.yaml"
    fi
    if pull "$PI_SYNAPSE/mautrix-$bridge/config.yaml" "cfg-$bridge.yaml"; then
      op_note_from_file "Mautrix $title_cc Config" "$STAGE/cfg-$bridge.yaml"
    fi
  done

  # ---- LiveKit: config file + API key/secret ----
  if pull "$PI_SYNAPSE/livekit.yaml" livekit.yaml; then
    op_note_from_file "LiveKit Config" "$STAGE/livekit.yaml"
    # keys: { <key>: <secret> }
    local lk_key lk_secret
    lk_key="$(yq -r '.keys | keys | .[0]' "$STAGE/livekit.yaml")"
    lk_secret="$(yq -r ".keys.\"$lk_key\"" "$STAGE/livekit.yaml")"
    if op_item_exists "LiveKit"; then
      run op item edit "LiveKit" --vault "$VAULT" "key=$lk_key" "secret=$lk_secret" >/dev/null
    else
      run op item create --category Login --vault "$VAULT" --title "LiveKit" \
        "key=$lk_key" "secret=$lk_secret" >/dev/null
    fi
  fi

  # ---- Sharkey: default.yml (rewrite db/redis hosts) + DB password ----
  if pull "$PI_SHARKEY/.config/default.yml" sharkey.default.yml; then
    yq '.db.host = "sharkey-db" | .redis.host = "sharkey-redis"' \
      "$STAGE/sharkey.default.yml" > "$STAGE/sharkey.default.fixed.yml"
    op_note_from_file "Sharkey Config" "$STAGE/sharkey.default.fixed.yml"

    local shk_db_pass
    shk_db_pass="$(yq -r '.db.pass' "$STAGE/sharkey.default.yml")"
    op_password "Sharkey DB" "$shk_db_pass"
  fi

  log "Secrets done."
}

# ── data ─────────────────────────────────────────────────────────────────────────────────
# Run rsync ON magicplank, pulling straight from the Pi, as root on both ends. This preserves
# the original numeric ownership (Postgres uid 70 / Synapse 991 / Redis 999 / ...) without any
# guessing. Auth to the Pi uses your forwarded ssh agent; when sudo is needed on magicplank we
# keep SSH_AUTH_SOCK across it, and root on the Pi side comes from PI_RSYNC_PATH.
sync_dir() { # sync_dir <pi-subdir> <mp-dest-subdir>
  local src="$1" dst="$2"
  if ! ssh "$PI" "$PI_SUDO test -d '$src'"; then
    warn "missing on Pi, skipping data: $src"
    return 0
  fi
  log "sync (on $MP)  $PI_FROM_MP:$src  ->  $MP_DATA/$dst"
  local mp_rsync="rsync"
  [ -n "$MP_SUDO" ] && mp_rsync="$MP_SUDO --preserve-env=SSH_AUTH_SOCK rsync"
  run ssh -A "$MP" "
    set -e
    $MP_SUDO mkdir -p '$MP_DATA/$dst'
    $mp_rsync -aHAX --numeric-ids --delete \
      -e 'ssh -A -o StrictHostKeyChecking=accept-new' \
      --rsync-path='$PI_RSYNC_PATH' \
      '$PI_FROM_MP:$src/' '$MP_DATA/$dst/'
  "
}

do_data() {
  warn "Stop the Pi stacks first (docker compose down) for a consistent Postgres copy."
  read -r -p "Press Enter once the Pi stacks are stopped (or Ctrl-C to abort)... " _

  # Synapse: Postgres cluster + media_store + bridge SQLite dbs.
  sync_dir "$PI_SYNAPSE/schemas"          "synapse-db"
  sync_dir "$PI_SYNAPSE/files/media_store" "synapse/media_store"
  sync_dir "$PI_SYNAPSE/mautrix-telegram"  "mautrix-telegram"
  sync_dir "$PI_SYNAPSE/mautrix-signal"    "mautrix-signal"
  sync_dir "$PI_SYNAPSE/mautrix-discord"   "mautrix-discord"
  # heisenbridge keeps almost no local state; create the dir so the bind-mount exists.
  run ssh "$MP" "$MP_SUDO mkdir -p '$MP_DATA/heisenbridge'"

  # Sharkey: uploaded files + Postgres (pgroonga) cluster + Redis.
  sync_dir "$PI_SHARKEY/files" "sharkey/files"
  sync_dir "$PI_SHARKEY/db"    "sharkey-db"
  sync_dir "$PI_SHARKEY/redis" "sharkey-redis"

  log "Data done. Now: nixos-rebuild switch on magicplank, then verify (see plan)."
}

# ── main ─────────────────────────────────────────────────────────────────────────────────
case "${1:-}" in
  secrets) do_secrets ;;
  data)    do_data ;;
  all)     do_secrets; do_data ;;
  *) echo "usage: $0 {secrets|data|all}   (env: PI, MP, VAULT, PI_SYNAPSE, PI_SHARKEY, MP_DATA, DRY_RUN)"; exit 1 ;;
esac
