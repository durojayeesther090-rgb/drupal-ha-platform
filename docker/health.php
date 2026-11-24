<?php
// Health check used by Docker, Kubernetes probes and load balancers.
// Healthy only when the database accepts a connection.
header('Content-Type: text/plain');
try {
  new PDO(
    'mysql:host=' . getenv('DB_HOST') . ';port=' . (getenv('DB_PORT') ?: '3306') . ';dbname=' . getenv('DB_NAME'),
    getenv('DB_USER'),
    getenv('DB_PASSWORD'),
    [PDO::ATTR_TIMEOUT => 3]
  );
  http_response_code(200);
  echo "ok\n";
}
catch (Throwable $e) {
  http_response_code(503);
  echo "database unavailable\n";
}
