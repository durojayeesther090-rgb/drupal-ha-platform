#!/usr/bin/env bash
# Smoke tests: quick checks that a running site is alive.
# Usage: tests/smoke.sh http://host[:port]
set -euo pipefail

BASE="${1:?Usage: smoke.sh BASE_URL}"
BASE="${BASE%/}"
fail=0

# check NAME PATH [TEXT THE PAGE MUST CONTAIN]
check() {
  local name="$1" path="$2" expect="${3:-}"
  local body code
  body="$(mktemp)"
  code="$(curl -sL --retry 5 --retry-delay 5 --retry-all-errors --max-time 30 -o "$body" -w '%{http_code}' "$BASE$path" || true)"
  if [ "$code" != "200" ]; then
    echo "FAIL  $name ($path): HTTP $code"
    fail=1
  elif [ -n "$expect" ] && ! grep -qi "$expect" "$body"; then
    echo "FAIL  $name ($path): expected text '$expect' not found"
    fail=1
  else
    echo "PASS  $name ($path)"
  fi
  rm -f "$body"
}

check "health endpoint" "/health.php" "ok"
check "front page" "/" "drupal"
check "login page" "/user/login" "log in"

if [ "$fail" -eq 0 ]; then
  echo "All smoke tests passed for $BASE"
fi
exit "$fail"
