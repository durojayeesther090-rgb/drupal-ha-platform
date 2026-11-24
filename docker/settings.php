<?php
// Container settings: everything comes from environment variables,
// so the same image runs in Docker Compose, Kubernetes and EKS.

$databases['default']['default'] = [
  'database' => getenv('DB_NAME') ?: 'drupal',
  'username' => getenv('DB_USER') ?: 'drupal',
  'password' => getenv('DB_PASSWORD') ?: '',
  'host' => getenv('DB_HOST') ?: 'db',
  'port' => getenv('DB_PORT') ?: '3306',
  'driver' => 'mysql',
  'prefix' => '',
  'namespace' => 'Drupal\\mysql\\Driver\\Database\\mysql',
  'autoload' => 'core/modules/mysql/src/Driver/Database/mysql/',
];

$settings['hash_salt'] = getenv('HASH_SALT') ?: 'change-me-before-real-use';
$settings['config_sync_directory'] = '/var/www/config/sync';
$settings['file_private_path'] = '/var/www/private';
$settings['update_free_access'] = FALSE;

// Regular expression for the host names this site answers to.
$settings['trusted_host_patterns'] = [
  getenv('TRUSTED_HOST_PATTERN') ?: '^localhost$',
];
