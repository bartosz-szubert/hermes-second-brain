#!/usr/bin/env bash
# Nightly backup of Hermes and n8n data to Backblaze B2 with restic.
# Runs as root from hermes-backup.timer. Secrets live only in /root/.restic (700/600).
set -uo pipefail
export TZ=Europe/Warsaw

# --- Paths (adjust to your host) -------------------------------------------
HERMES_DIR=/docker/hermes-agent            # compose project of the agent
H="$HERMES_DIR/data"                        # agent data (profiles, skills, sessions)
N8N=/var/lib/docker/volumes/n8n_data/_data  # n8n data volume
N8N_DIR=/docker/n8n                         # n8n compose project
VAULT_SYNC=/opt/hermes-vault-sync           # host-side vault write path (its repo clone is excluded)
STAGE=/var/backups/hermes-sqlite            # root-only staging for consistent SQLite copies
# ---------------------------------------------------------------------------
STATUS_DIR="$H/agent-data/status"     # readable by Hermes, owned by root (interim until the script-based self-check)
STATUS="$STATUS_DIR/backup.txt"

now() { date '+%Y-%m-%d %H:%M'; }

write_status() {
  mkdir -p "$STATUS_DIR" && chown root:root "$STATUS_DIR" && chmod 755 "$STATUS_DIR"
  printf '%s\n' "$1" > "$STATUS.tmp" && chmod 644 "$STATUS.tmp" && mv -f "$STATUS.tmp" "$STATUS"
}

fail() {
  local msg; msg="$(now) | backup | BŁĄD: $1"
  echo "$msg" >&2
  write_status "$msg"
  exit 1
}

[ -r /root/.restic/env ] || fail "brak pliku /root/.restic/env"
# shellcheck disable=SC1091
. /root/.restic/env

# 1. Consistent copies of every SQLite database (never copy a live database file raw).
#    Sources are opened as root (owners cannot always traverse e.g. /var/lib/docker). Any -wal/-shm
#    file that this creates is handed back to the database owner, so the app never loses access.
if ! { rm -rf "$STAGE" && mkdir -p "$(dirname "$STAGE")" && mkdir -m 700 "$STAGE"; }; then
  fail "nie można utworzyć $STAGE"
fi
COUNT=$(python3 -I - "$STAGE" "$H" "$N8N" <<'PY'
import os, sqlite3, sys, pathlib
stage = pathlib.Path(sys.argv[1]); roots = sys.argv[2:]
skip = {'home', 'bin', 'lazy-packages', '.local', 'cache', 'tmp', 'node_modules'}
n = 0
for root in roots:
    for p in pathlib.Path(root).rglob('*'):
        if p.suffix not in ('.db', '.sqlite', '.sqlite3') or not p.is_file():
            continue
        if skip.intersection(p.relative_to(root).parts):
            continue
        st = p.stat()
        side = [pathlib.Path(str(p) + x) for x in ('-wal', '-shm')]
        try:
            src = sqlite3.connect(str(p), timeout=60)
            mem = sqlite3.connect(':memory:')
            src.backup(mem); src.close()
        finally:
            for f in side:
                if f.exists() and (f.stat().st_uid, f.stat().st_gid) != (st.st_uid, st.st_gid):
                    os.chown(f, st.st_uid, st.st_gid)
        dst = stage / (str(p.relative_to('/')) + '.snapshot')
        dst.parent.mkdir(parents=True, exist_ok=True)
        out = sqlite3.connect(str(dst)); mem.backup(out); out.close(); mem.close()
        n += 1
print(n)
PY
) || fail "kopia baz SQLite nie powiodła się"
[ "${COUNT:-0}" -gt 0 ] || fail "nie znaleziono żadnej bazy SQLite"

# 2. Back up (databases come from the staging copies; live database files are excluded).
restic unlock >/dev/null 2>&1   # removes stale locks only
SUMMARY=$(restic backup --json --quiet --tag nightly \
  "$H" "$N8N" "$STAGE" \
  "$VAULT_SYNC" \
  "$HERMES_DIR/docker-compose.yml" "$HERMES_DIR/.env" \
  "$N8N_DIR" \
  /usr/local/sbin/hermes-backup.sh /etc/systemd/system/hermes-backup.service /etc/systemd/system/hermes-backup.timer \
  --exclude "$H/home" --exclude "$H/bin" --exclude "$H/lazy-packages" --exclude "$H/.local" \
  --exclude "$H/cache" --exclude "$H/tmp" --exclude "$VAULT_SYNC/repo" \
  --exclude '__pycache__' \
  --exclude '*.db' --exclude '*.db-wal' --exclude '*.db-shm' --exclude '*.db-journal' \
  --exclude '*.sqlite' --exclude '*.sqlite-wal' --exclude '*.sqlite-shm' --exclude '*.sqlite-journal' \
  --exclude '*.sqlite3' --exclude '*.sqlite3-wal' --exclude '*.sqlite3-shm' \
  | tail -n 1) || fail "restic backup zakończony błędem"
INFO=$(printf '%s' "$SUMMARY" | python3 -I -c 'import json,sys; d=json.load(sys.stdin); print(d["snapshot_id"][:8], round(d.get("data_added",0)/1e6,1))') \
  || fail "brak podsumowania restic backup"
SNAP=${INFO% *}; ADDED=${INFO#* }

# 3. Retention 7 daily / 4 weekly / 6 monthly. The B2 key cannot delete, so pruned files are hidden;
#    the bucket lifecycle rule removes hidden files after 30 days.
restic forget --quiet --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune >/dev/null \
  || fail "restic forget/prune zakończony błędem (kopia $SNAP zapisana)"

# 4. Monthly integrity check.
CHECK="—"
if [ "$(date +%d)" = "01" ]; then
  restic check --quiet >/dev/null || fail "restic check wykrył problem (kopia $SNAP zapisana)"
  CHECK="OK"
fi

rm -rf "$STAGE"
write_status "$(now) | backup | OK | kopia $SNAP | bazy: $COUNT | dodano ${ADDED} MB | check: $CHECK"
echo "backup OK: snapshot $SNAP, $COUNT databases, ${ADDED} MB added, check: $CHECK"
