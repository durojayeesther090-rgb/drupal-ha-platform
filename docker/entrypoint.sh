#!/bin/sh
set -e

FILES=/opt/drupal/web/sites/default/files
mkdir -p "$FILES" /var/www/private /var/www/config/sync
# Volumes may be created as root; ignore errors on storage that does not allow chown
chown www-data:www-data "$FILES" /var/www/private /var/www/config/sync 2>/dev/null || true

wait_for_db() {
  until php -r 'new PDO("mysql:host=".getenv("DB_HOST").";port=".(getenv("DB_PORT")?:"3306").";dbname=".getenv("DB_NAME"), getenv("DB_USER"), getenv("DB_PASSWORD"));' >/dev/null 2>&1; do
    echo "Waiting for the database..."
    sleep 3
  done
}

run_install() {
  if su -s /bin/sh www-data -c "HOME=/tmp drush --root=/opt/drupal/web status --field=bootstrap" 2>/dev/null | grep -q Successful; then
    echo "Drupal is already installed."
  else
    echo "Installing Drupal..."
    su -s /bin/sh www-data -c "HOME=/tmp drush --root=/opt/drupal/web site:install standard --yes --account-name=admin --account-pass='${DRUPAL_ADMIN_PASSWORD:-admin}' --site-name='${DRUPAL_SITE_NAME:-Drupal HA Platform}'"
  fi
}

# "install" runs the installer once and exits (used by the Kubernetes Job)
if [ "${1:-}" = "install" ]; then
  wait_for_db
  run_install
  exit 0
fi

# For local Docker Compose: install automatically on first start
if [ "${DRUPAL_AUTO_INSTALL:-false}" = "true" ]; then
  wait_for_db
  run_install
fi

exec docker-php-entrypoint "$@"
