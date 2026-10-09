#!/usr/bin/env bash
# migrate-spack-buildcache.sh
# Migrates a Spack OCI buildcache from one GHCR repo to another using ORAS.
# Requires: oras >= 1.2.0, curl, jq
#
# Usage:
#   export SRC_REPO="old-org/my-buildcache"
#   export DST_REPO="new-org/my-buildcache"
#   export SRC_TOKEN=ghp_...   # PAT with read:packages
#   export DST_TOKEN=ghp_...   # PAT with write:packages
#   ./migrate-spack-buildcache.sh
#
# After completion, rebuild the index on the new mirror:
#   spack mirror add --oci-username githubuser --oci-password DST_TOKEN new-cache oci://ghcr.io/$DST_REPO
#   spack buildcache update-index new-cache

set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────────
SRC_REGISTRY="${SRC_REGISTRY:-ghcr.io}"
DST_REGISTRY="${DST_REGISTRY:-ghcr.io}"
SRC_REPO="${SRC_REPO:?Set SRC_REPO, e.g. old-org/my-buildcache}"
DST_REPO="${DST_REPO:?Set DST_REPO, e.g. new-org/my-buildcache}"
SRC_TOKEN="${SRC_TOKEN:?Set SRC_TOKEN}"
DST_TOKEN="${DST_TOKEN:?Set DST_TOKEN}"

# Number of parallel oras cp jobs — tune based on your network
PARALLEL="${PARALLEL:-4}"

LOG_DIR="${LOG_DIR:-./migrate-logs}"
DONE_FILE="$LOG_DIR/done.txt"
FAILED_FILE="$LOG_DIR/failed.txt"
TAGS_FILE="$LOG_DIR/tags.txt"
# ──────────────────────────────────────────────────────────────────────────────

mkdir -p "$LOG_DIR"
touch "$DONE_FILE" "$FAILED_FILE"

log() { echo "[$(date -u +%H:%M:%S)] $*"; }

# ─── Auth ─────────────────────────────────────────────────────────────────────
log "Logging in to $SRC_REGISTRY..."
echo "$SRC_TOKEN" | oras login "$SRC_REGISTRY" --username "${SRC_USER:-_token}" --password-stdin

log "Logging in to $DST_REGISTRY..."
echo "$DST_TOKEN" | oras login "$DST_REGISTRY" --username "${DST_USER:-_token}" --password-stdin

# Exchange PAT for a GHCR-scoped Bearer token for curl calls.
# GHCR returns the PAT base64-encoded as the Bearer token.
log "Fetching GHCR Bearer token..."
SRC_BEARER=$(curl -fsSL \
  -u "${SRC_USER:-_token}:$SRC_TOKEN" \
  "https://${SRC_REGISTRY}/token?service=${SRC_REGISTRY}&scope=repository:${SRC_REPO}:pull" \
  | jq -r '.token')

# ─── Fetch all .spack tags via OCI registry API (paginated) ───────────────────
fetch_spack_tags() {
  local url="https://${SRC_REGISTRY}/v2/${SRC_REPO}/tags/list"
  local last=""

  log "Fetching .spack tags from $SRC_REGISTRY/$SRC_REPO..."

  while true; do
    local query_url="$url?n=1000${last:+&last=$last}"
    local response
    response=$(curl -fsSL \
      -H "Authorization: Bearer $SRC_BEARER" \
      "$query_url")

    local page_tags
    page_tags=$(echo "$response" | jq -r '.tags[]? | select(endswith(".spack"))')

    if [[ -n "$page_tags" ]]; then
      echo "$page_tags"
      last=$(echo "$page_tags" | tail -1)
    fi

    # Stop if we got fewer than 1000 tags (last page)
    local count
    count=$(echo "$response" | jq '.tags | length')
    [[ "$count" -lt 1000 ]] && break
  done
}

# ─── Copy one tagged artifact ──────────────────────────────────────────────────
copy_tag() {
  local tag="$1"
  local src="${SRC_REGISTRY}/${SRC_REPO}:${tag}"
  local dst="${DST_REGISTRY}/${DST_REPO}:${tag}"

  # Resume: skip if already done
  if grep -qxF "$tag" "$DONE_FILE" 2>/dev/null; then
    return 0
  fi

  if oras cp \
      --concurrency 4 \
      "$src" "$dst" \
      >> "$LOG_DIR/oras.log" 2>&1; then
    echo "$tag" >> "$DONE_FILE"
    log "OK: $tag"
  else
    echo "$tag" >> "$FAILED_FILE"
    log "FAILED: $tag"
  fi
}

export -f copy_tag log
export SRC_REGISTRY DST_REGISTRY SRC_REPO DST_REPO DONE_FILE FAILED_FILE LOG_DIR SRC_BEARER

# ─── Main ─────────────────────────────────────────────────────────────────────
fetch_spack_tags | tee "$TAGS_FILE" | \
  xargs -P "$PARALLEL" -I{} bash -c 'copy_tag "$@"' _ {}

# ─── Summary ──────────────────────────────────────────────────────────────────
TOTAL=$(wc -l < "$TAGS_FILE")
DONE=$(wc -l < "$DONE_FILE")
FAILED=$(wc -l < "$FAILED_FILE")

log "=== Done ==="
log "  Total .spack tags: $TOTAL"
log "  Copied:            $DONE"
log "  Failed:            $FAILED"

if [[ "$FAILED" -gt 0 ]]; then
  log "  Failed tags: $FAILED_FILE"
  log "  Re-run to retry — already-copied tags will be skipped."
  exit 1
fi

log ""
log "Next step — rebuild the index on the new mirror:"
log "  spack mirror add new-cache oci://${DST_REGISTRY}/${DST_REPO}"
log "  spack buildcache update-index new-cache"
