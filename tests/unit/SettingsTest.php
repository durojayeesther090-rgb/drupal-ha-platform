<?php

use PHPUnit\Framework\TestCase;

/**
 * Unit tests for docker/settings.php (reads all configuration from the environment).
 */
final class SettingsTest extends TestCase {

  private const VARIABLES = [
    'DB_NAME', 'DB_USER', 'DB_PASSWORD', 'DB_HOST', 'DB_PORT',
    'HASH_SALT', 'TRUSTED_HOST_PATTERN',
  ];

  protected function tearDown(): void {
    foreach (self::VARIABLES as $name) {
      putenv($name);
    }
  }

  /**
   * Loads settings.php with the given environment variables.
   *
   * @return array{0: array, 1: array}
   *   The $databases and $settings arrays it defines.
   */
  private function loadSettings(array $env): array {
    foreach (self::VARIABLES as $name) {
      putenv($name);
    }
    foreach ($env as $name => $value) {
      putenv("$name=$value");
    }
    $databases = [];
    $settings = [];
    include __DIR__ . '/../../docker/settings.php';
    return [$databases, $settings];
  }

  public function testDatabaseSettingsComeFromEnvironment(): void {
    [$databases] = $this->loadSettings([
      'DB_NAME' => 'mydb',
      'DB_USER' => 'myuser',
      'DB_PASSWORD' => 'secret',
      'DB_HOST' => 'db.example.internal',
      'DB_PORT' => '3307',
    ]);
    $db = $databases['default']['default'];
    $this->assertSame('mydb', $db['database']);
    $this->assertSame('myuser', $db['username']);
    $this->assertSame('secret', $db['password']);
    $this->assertSame('db.example.internal', $db['host']);
    $this->assertSame('3307', $db['port']);
    $this->assertSame('mysql', $db['driver']);
  }

  public function testDatabaseDefaultsWhenNothingIsSet(): void {
    [$databases] = $this->loadSettings([]);
    $db = $databases['default']['default'];
    $this->assertSame('drupal', $db['database']);
    $this->assertSame('db', $db['host']);
    $this->assertSame('3306', $db['port']);
  }

  public function testHashSaltComesFromEnvironment(): void {
    [, $settings] = $this->loadSettings(['HASH_SALT' => 'abc123']);
    $this->assertSame('abc123', $settings['hash_salt']);
  }

  public function testTrustedHostPatternComesFromEnvironment(): void {
    [, $settings] = $this->loadSettings(['TRUSTED_HOST_PATTERN' => '^example\.com$']);
    $this->assertSame(['^example\.com$'], $settings['trusted_host_patterns']);
  }

  public function testTrustedHostsDefaultToLocalhostOnly(): void {
    [, $settings] = $this->loadSettings([]);
    $this->assertSame(['^localhost$'], $settings['trusted_host_patterns']);
  }

  public function testUpdateAccessIsDisabled(): void {
    [, $settings] = $this->loadSettings([]);
    $this->assertFalse($settings['update_free_access']);
  }

}
