#!/usr/bin/env bash
# Builds the release zips for htb_garage, one per framework.
#
#   .github/scripts/package.sh <version> [out-dir]
#
# Expects the UI to be built already (htb_garage-ui -> UI/index.html).
# Each zip holds a single htb_garage/ folder with the runtime files, the
# framework's manifest renamed to fxmanifest.lua, and only UI/index.html from
# the UI (no Vue/Node project source).
set -euo pipefail

VERSION="${1:?usage: package.sh <version> [out-dir]}"
OUT="${2:-dist}"
RESOURCE="htb_garage"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# Runtime files and folders shipped in every zip. Anything not listed here
# (htb_garage-ui/, .github/, dev notes, the other manifests) stays out.
INCLUDE=(
  Bridge
  Client
  Configs
  Server
  SQL
  locales
  Config.lua
  VehicleStuff.lua
  common.lua
  constants.lua
  LICENSE
  README.md
)

# framework name in the zip -> manifest in the repo
declare -A MANIFESTS=(
  [esx]=fxmanifest-esx.lua
  [qbcore]=fxmanifest-qb.lua
)

[[ -f UI/index.html ]] || { echo "UI/index.html missing: build htb_garage-ui first" >&2; exit 1; }

rm -rf "$OUT"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"

for framework in esx qbcore; do
  manifest="${MANIFESTS[$framework]}"

  # The manifest version must match the release version (v2.1.0 -> 2.1.0).
  manifest_version="$(sed -n 's/^version("\(.*\)").*/\1/p' "$manifest")"
  if [[ "$manifest_version" != "$VERSION" ]]; then
    echo "$manifest has version(\"$manifest_version\"), expected \"$VERSION\"" >&2
    exit 1
  fi

  stage="$OUT/stage-$framework"
  dest="$stage/$RESOURCE"
  mkdir -p "$dest/UI"

  for item in "${INCLUDE[@]}"; do
    cp -R "$item" "$dest/"
  done
  cp UI/index.html "$dest/UI/index.html"
  cp "$manifest" "$dest/fxmanifest.lua"

  # Every local file the manifest names must be in the package.
  missing=0
  while IFS= read -r ref; do
    shopt -s nullglob
    # shellcheck disable=SC2206
    matches=( "$dest"/$ref )
    shopt -u nullglob
    if (( ${#matches[@]} == 0 )); then
      echo "[$framework] fxmanifest.lua references '$ref' but it is not in the package" >&2
      missing=1
    fi
  done < <(grep -v '^\s*--' "$dest/fxmanifest.lua" \
            | grep -o '"[^"@][^"]*\.\(lua\|html\)"' | tr -d '"' | grep -v '^http')
  (( missing == 0 )) || exit 1

  zip_name="${RESOURCE}-v${VERSION}-${framework}.zip"
  if command -v zip >/dev/null 2>&1; then
    (cd "$stage" && zip -qr -X "$OUT/$zip_name" "$RESOURCE")
  else
    # Local fallback (e.g. Git Bash on Windows has no zip).
    (cd "$stage" && python -c 'import shutil,sys; shutil.make_archive(sys.argv[1], "zip", ".", sys.argv[2])' \
      "$OUT/${zip_name%.zip}" "$RESOURCE")
  fi
  rm -rf "$stage"
  echo "Built $OUT/$zip_name"
done
