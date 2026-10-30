<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'mailgun' => [
        'domain' => env('MAILGUN_DOMAIN'),
        'secret' => env('MAILGUN_SECRET'),
        'endpoint' => env('MAILGUN_ENDPOINT', 'api.mailgun.net'),
    ],

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    /*
    | The Verifico — PAN NSDL verify (not Cashfree).
    | Key: VERIFICO_API_KEY in .env only. Host: api.theverifico.com
    */
    'verifico' => [
        'key' => env('VERIFICO_API_KEY'),
        'base_url' => env('VERIFICO_BASE_URL', 'https://api.theverifico.com'),
        'pan_enabled' => env('VERIFICO_PAN_ENABLED', true),
    ],

];
