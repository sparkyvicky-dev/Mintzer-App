<?php
header('Content-Type: application/json; charset=utf-8');
if (($_GET['k'] ?? '') !== 'RO_GST_ONCE') { http_response_code(404); echo '{"e":1}'; exit; }
try {
  $envFile = dirname(__DIR__) . '/.env';
  $env = [];
  foreach (file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
    $line = trim($line);
    if ($line === '' || $line[0] === '#' || strpos($line, '=') === false) continue;
    [$k,$v] = explode('=', $line, 2);
    $env[trim($k)] = trim($v, " \t\"'");
  }
  $db = new mysqli($env['DB_HOST']??'localhost', $env['DB_USERNAME']??'', $env['DB_PASSWORD']??'', $env['DB_DATABASE']??'', (int)($env['DB_PORT']??3306));
  $q = "SELECT id, name, gst_number, company_name, pin_code, CHAR_LENGTH(gst_number) AS glen
        FROM deals WHERE gst_number IS NOT NULL AND gst_number <> ''
        ORDER BY id DESC LIMIT 15";
  $rows = $db->query($q)->fetch_all(MYSQLI_ASSOC);
  echo json_encode(['deals'=>$rows], JSON_PRETTY_PRINT);
  $db->close();
} catch (Throwable $e) { http_response_code(500); echo json_encode(['error'=>$e->getMessage()]); }
