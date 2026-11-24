#!/usr/bin/env bash
# Integration tests against the Docker Compose stack (web container + database).
# Run from the repository root after:  docker compose up -d --build --wait
set -euo pipefail

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }

# Run a command inside the Drupal container as the web server user
drupal() { docker compose exec -T -u www-data drupal env HOME=/tmp "$@"; }
drush() { drupal drush --root=/opt/drupal/web "$@"; }

# 1. Drupal is installed and bootstrapped
[ "$(drush status --field=bootstrap | tr -d '[:space:]')" = "Successful" ] || fail "Drupal did not bootstrap"
pass "Drupal is installed and bootstraps"

# 2. Drupal talks to the database
users=$(drush php:eval "echo \Drupal::database()->query('SELECT COUNT(*) FROM {users_field_data}')->fetchField();")
[ "${users//[[:space:]]/}" -ge 2 ] || fail "expected at least 2 user rows, got: $users"
pass "database query works ($users user rows)"

# 3. The admin account exists
drush user:information admin > /dev/null || fail "admin user not found"
pass "admin user exists"

# 4. Scheduled tasks (cron) run without errors
drush core:cron > /dev/null || fail "cron failed"
pass "cron runs"

# 5. Uploaded files survive a container restart (shared volume)
drupal sh -c 'echo persisted > /opt/drupal/web/sites/default/files/ci-test.txt'
docker compose restart drupal > /dev/null
bash "$(dirname "$0")/smoke.sh" http://localhost:8080 > /dev/null
drupal test -f /opt/drupal/web/sites/default/files/ci-test.txt || fail "file was lost after restart"
pass "files persist across a restart"

echo "All integration tests passed"
