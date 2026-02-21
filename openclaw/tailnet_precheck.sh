#!/usr/bin/env bash
set -euo pipefail

target="${P6AM_TAILNET_TARGET:-}"
ping_timeout="${P6AM_TAILNET_PING_TIMEOUT_SEC:-5}"

if [ -z "$target" ]; then
  echo "P6AM_TAILNET_TARGET is required" >&2
  exit 1
fi

if ! command -v tailscale >/dev/null 2>&1; then
  echo "tailscale command not found" >&2
  exit 1
fi

if ! tailscale status >/dev/null 2>&1; then
  echo "tailscale status check failed" >&2
  exit 1
fi

if ! tailscale ping --timeout="${ping_timeout}s" "$target" >/dev/null 2>&1; then
  echo "tailscale ping failed: target=${target}" >&2
  exit 1
fi

echo "tailnet precheck: OK"
