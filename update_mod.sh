#!/bin/bash
set -euo pipefail

# Global Settings
# Mod Update Settings
BASE_PATH="/home/peter/factorio"
MOD_HOST="mods.factorio.com"
MODS_PATH=""
SERVER_SETTINGS=""
DRY_RUN=false
EXCLUDE_FILE=""
FORCE_EXCLUDE_MODS=("base" "elevated-rails" "quality" "space-age")
# Backup Settings
BACKUP_REQUESTED=false
RESTORE_FILE=""
BACKUP_DIR=""
############################################
# Helper Functions
############################################
usage() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -s, --server-settings PATH   server-settings.json location"
  echo "  -u, --username USERNAME      factorio.com account"
  echo "  -t, --token TOKEN            factorio.com token"
  echo "  --mod-host SERVER            Mods Server (Default: mods.factorio.com)"
  echo "  -p, --path PATH              Factorio install root"
  echo "  -m, --mods-path PATH         Mods folder path"
  echo "  -e, --exclude-list PATH      Exclude mod FILES"
  echo "  -n, --dry-run                Only check version, no download"
  echo "  --backup                     Backup mods (mods_backup_YYYYMMDD_HHMMSS.tar.gz)" 
  echo "  --restore FILE_PATH          Restore from backup (mods_backup_YYYYMMDD_HHMMSS.tar.gz)" 
  echo "  -h, --help                   Show help"
  exit 1
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -s|--server-settings) SERVER_SETTINGS="$2"; shift 2 ;;
      -u|--username) USERNAME="$2"; shift 2 ;;
      -t|--token) TOKEN="$2"; shift 2 ;;
      --mod-host) MOD_HOST="$2"; shift 2 ;;
      -p|--path) BASE_PATH="$2"; shift 2 ;;
      -m|--mods-path) MODS_PATH="$2"; shift 2 ;;
      -e|--exclude-list) EXCLUDE_FILE="$2"; shift 2 ;;
      -n|--dry-run) DRY_RUN=true; shift ;;
      --backup) BACKUP_REQUESTED=true; shift ;;
      --restore) RESTORE_FILE="$2"; shift 2 ;;
      -h|--help) usage ;;
      *) echo "Unknown argument: $1"; usage ;;
    esac
  done
}

check_dependencies() {
  for cmd in jq curl; do
    if ! command -v "$cmd" >/dev/null; then
      echo "Missing command '$cmd'. Try: sudo apt install $cmd"
      exit 1
    fi
  done
}

load_credentials() {
  if [[ -z "${USERNAME:-}" || -z "${TOKEN:-}" ]]; then
    if [[ ! -f "$SERVER_SETTINGS" ]]; then
      echo "Missing server-settings.json: $SERVER_SETTINGS"
      exit 1
    fi
    USERNAME=$(jq -r '.username' "$SERVER_SETTINGS")
    TOKEN=$(jq -r '.token' "$SERVER_SETTINGS")
  fi
}

get_mod_names() {
  local mod_list="$MODS_PATH/mod-list.json"
  if [[ ! -f "$mod_list" ]]; then
    echo "Missing mod-list.json: $mod_list"
    exit 1
  fi

  local mods
  mods=$(jq -r '.mods[].name' "$mod_list")

  for EX in "${FORCE_EXCLUDE_MODS[@]}"; do
    mods=$(echo "$mods" | grep -v -x "$EX" || true)
  done

  if [[ -n "$EXCLUDE_FILE" && -f "$EXCLUDE_FILE" ]]; then
    mapfile -t EXCLUDE_MODS < "$EXCLUDE_FILE"
    for EX in "${EXCLUDE_MODS[@]}"; do
      mods=$(echo "$mods" | grep -v -x "$EX" || true)
    done
  fi

  echo "$mods"
}

fetch_and_update_mods() {
  local mod_names="$1"
  local joined_mods
  joined_mods=$(echo "$mod_names" | paste -sd ',' -)

  [[ -z "$joined_mods" ]] && {
    echo "No mods to process. Check exclusions."
    exit 0
  }

  echo "Checking: $joined_mods"
  local mod_api="https://${MOD_HOST}/api/mods?page_size=max&namelist=${joined_mods}"
  local mod_results
  mod_results=$(curl -s "$mod_api")

  echo "$mod_results" | jq -c '.results[]' | while read -r mod; do
    process_mod "$mod"
  done
}

process_mod() {
  local mod="$1"
  local name owner releases version release file_name dl_path mod_file

  name=$(echo "$mod" | jq -r '.name')
  owner=$(echo "$mod" | jq -r '.owner')
  releases=$(echo "$mod" | jq -c '.releases')
  version=$(echo "$releases" | jq -r '.[].version' | sort -V | tail -n1)
  release=$(echo "$releases" | jq -c --arg ver "$version" '.[] | select(.version == $ver)')
  file_name=$(echo "$release" | jq -r '.file_name')
  dl_path=$(echo "$release" | jq -r '.download_url')
  mod_file="$MODS_PATH/$file_name"

  local local_file local_version status
  local_file=$(find "$MODS_PATH" -name "${name}_*.zip" | head -n1)
  local_version="(none)"
  [[ -n "$local_file" ]] && local_version=$(basename "$local_file" | sed -E "s/^${name}_([0-9.]+)\.zip$/\1/")

  if [[ -f "$mod_file" ]]; then
    status="No Changed"
  else
    if [[ "$DRY_RUN" = true ]]; then
      status="Need Updated"
    else
      local download_url="https://${MOD_HOST}${dl_path}?username=${USERNAME}&token=${TOKEN}"
      curl -s -L "$download_url" -o "$mod_file.tmp"
      if ! file "$mod_file.tmp" | grep -q "Zip archive data"; then
        echo "Download failed or invalid zip. Check credentials."
        rm -f "$mod_file.tmp"
        exit 1
      fi
      find "$MODS_PATH" -name "${name}_*.zip" -delete
      mv "$mod_file.tmp" "$mod_file"
      status="Update Completed"
    fi
  fi

  echo "$name by $owner $local_version → $version $status"
}

backup_mods() {
  mkdir -p "$BACKUP_DIR"
  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_file="$BACKUP_DIR/mods_backup_$timestamp.tar.gz"

  echo "Creating backup to $backup_file"
  tar -czf "$backup_file" -C "$MODS_PATH" .
  echo "Backup complete."
}

restore_mods() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    echo "Backup file not found: $file"
    exit 1
  fi

  echo "Restoring mods from $file"
  mkdir -p "$MODS_PATH"
  rm -rf "${MODS_PATH:?}"/*
  tar -xzf "$file" -C "$MODS_PATH"
  echo "Restore complete."
}


main() {
  parse_args "$@"
  MODS_PATH="${MODS_PATH:-$BASE_PATH/mods}"
  SERVER_SETTINGS="${SERVER_SETTINGS:-$BASE_PATH/data/server-settings.json}"
  BACKUP_DIR="${BACKUP_DIR:-$BASE_PATH/mod_backup}" 
  check_dependencies
  
  # Backup
  if [[ "$BACKUP_REQUESTED" = true ]]; then
    backup_mods
    exit 0
  fi
  
  # Restore
  if [[ -n "$RESTORE_FILE" ]]; then
    restore_mods "$RESTORE_FILE"
    exit 0
  fi

  # Update Mods
  load_credentials
  local mods
  mods=$(get_mod_names)
  fetch_and_update_mods "$mods"
}

main "$@"
