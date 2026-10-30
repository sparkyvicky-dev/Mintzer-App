<?php



namespace App\Services\AdminApp;



use Google\Auth\Credentials\ServiceAccountCredentials;



/**

 * Firebase HTTP v1 — Admin app push (mintzer-e45d6).

 */

class AdminFcmClient

{

    /** Last failure reason for test-push diagnostics (not for end users normally). */

    public static ?string $lastError = null;



    public static function sendToToken(string $token, string $title, string $body, array $data = []): bool

    {

        self::$lastError = null;



        if ($token === '') {

            self::$lastError = 'empty_token';

            return false;

        }



        $path = self::credentialsPath();

        if ($path === null) {

            self::$lastError = 'missing_firebase_json';

            return false;

        }



        $projectId = self::projectIdFromPath($path);

        if ($projectId === null) {

            self::$lastError = 'invalid_firebase_json';

            return false;

        }



        $accessToken = self::accessToken($path);

        if ($accessToken === null) {

            return false;

        }



        $payload = [

            'message' => [

                'token' => $token,

                'notification' => [

                    'title' => $title,

                    'body' => $body,

                ],

                'data' => array_map('strval', $data),

                'android' => [

                    'priority' => 'high',

                ],

            ],

        ];



        $url = 'https://fcm.googleapis.com/v1/projects/' . $projectId . '/messages:send';

        $ch = curl_init($url);

        curl_setopt_array($ch, [

            CURLOPT_POST => true,

            CURLOPT_HTTPHEADER => [

                'Authorization: Bearer ' . $accessToken,

                'Content-Type: application/json',

            ],

            CURLOPT_POSTFIELDS => json_encode($payload),

            CURLOPT_RETURNTRANSFER => true,

            CURLOPT_TIMEOUT => 15,

        ]);

        $response = curl_exec($ch);

        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);

        $curlErr = curl_error($ch);

        curl_close($ch);



        if ($response === false || $code < 200 || $code >= 300) {

            self::$lastError = 'fcm_http_' . $code . ($curlErr !== '' ? (':' . $curlErr) : '');

            if (is_string($response) && $response !== '') {

                self::$lastError .= ':' . substr($response, 0, 180);

            }

            return false;

        }



        return true;

    }



    private static function accessToken(string $path): ?string

    {

        try {

            $credentials = new ServiceAccountCredentials(

                'https://www.googleapis.com/auth/firebase.messaging',

                $path

            );

            $token = $credentials->fetchAuthToken();

            $access = $token['access_token'] ?? null;

            if (!$access) {

                self::$lastError = 'auth_token_empty';

                return null;

            }



            return $access;

        } catch (\Throwable $e) {

            self::$lastError = 'auth_exception:' . $e->getMessage();

            return null;

        }

    }



    public static function credentialsPath(): ?string

    {

        $candidates = [

            public_path('mintzer-e45d6-firebase.json'),

            storage_path('app/firebase/mintzer-e45d6.json'),

            base_path('mintzer-e45d6-firebase.json'),

            // Legacy holder-app project (fallback only)

            public_path('mintzer-e14bd-b876d21e557c.json'),

            public_path('mintzer-e14bd-firebase.json'),

        ];



        foreach ($candidates as $candidate) {

            if (is_readable($candidate)) {

                return $candidate;

            }

        }



        foreach ([public_path(), base_path()] as $dir) {

            if (!is_dir($dir)) {

                continue;

            }

            foreach (['mintzer-e45d6*.json', 'mintzer-e14bd*.json'] as $pattern) {

                $matches = glob(rtrim($dir, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR . $pattern) ?: [];

                foreach ($matches as $match) {

                    if (is_readable($match)) {

                        return $match;

                    }

                }

            }

        }



        return null;

    }



    private static function projectIdFromPath(string $path): ?string

    {

        $raw = @file_get_contents($path);

        if ($raw === false) {

            return null;

        }

        $json = json_decode($raw, true);

        $projectId = $json['project_id'] ?? null;



        return is_string($projectId) && $projectId !== '' ? $projectId : null;

    }

}


