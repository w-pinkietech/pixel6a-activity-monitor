#!/usr/bin/env bash
set -euo pipefail

log_dir="${P6AM_LOG_DIR:-tmp/logs}"
retention_days="${P6AM_LOG_RETENTION_DAYS:-7}"

if [ ! -d "$log_dir" ]; then
  echo "log directory not found: ${log_dir}"
  exit 0
fi

if ! printf '%s' "$retention_days" | grep -Eq '^[0-9]+$'; then
  echo "P6AM_LOG_RETENTION_DAYS must be numeric" >&2
  exit 1
fi

if [ "$retention_days" -le 0 ]; then
  echo "P6AM_LOG_RETENTION_DAYS must be greater than 0" >&2
  exit 1
fi

delete_before_days="$((retention_days - 1))"
deleted_count="$(find "$log_dir" -type f -name '*.log' -mtime "+${delete_before_days}" -print | wc -l | tr -d ' ')"
find "$log_dir" -type f -name '*.log' -mtime "+${delete_before_days}" -delete

echo "log rotate done dir=${log_dir} retention_days=${retention_days} deleted=${deleted_count}"
