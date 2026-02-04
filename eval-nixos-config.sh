#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  eval-nixos-config.sh -s <system> -m <modules> -c <config_path>

Examples:
  eval-nixos-config.sh \
    -s x86_64-linux \
    -m $'nixos.arion\nnixos.someOther' \
    -c virtualisation.arion.backend
EOF
}

SYSTEM=""
MODULES=""
CONFIG_PATH=""

while getopts ":s:m:c:h" opt; do
  case "$opt" in
    s) SYSTEM="$OPTARG" ;;
    m) MODULES="$OPTARG" ;;
    c) CONFIG_PATH="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$SYSTEM" || -z "$MODULES" || -z "$CONFIG_PATH" ]]; then
  usage
  exit 1
fi

echo "Evaluating: " >&2
echo "System type: ${SYSTEM}" >&2
echo "Imported modules:" >&2
while IFS= read -r mod; do
  [[ -z "$mod" ]] && continue
  echo "  - flake.modules.${mod}" >&2
done <<< "$MODULES"
echo "Evaluating config path ${CONFIG_PATH}" >&2
echo "" >&2

# Build Nix modules list with "flake.modules." prefix
MODULES_NIX=""
while IFS= read -r mod; do
  [[ -z "$mod" ]] && continue
  MODULES_NIX+="      flake.modules.${mod}"$'\n'
done <<< "$MODULES"

nix eval --impure --expr "
let
  flake = builtins.getFlake (toString ./.);
  system = \"${SYSTEM}\";
  nixpkgs = flake.inputs.nixpkgs;
in
  (nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
${MODULES_NIX}    ];
  }).config.${CONFIG_PATH}
"