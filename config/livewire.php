<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Livewire App URL
    |--------------------------------------------------------------------------
    |
    | Override default URL generation to always use HTTPS. This fixes
    | the mixed-content issue when behind reverse proxies like Traefik,
    | Caddy, or Nginx in Coolify environments.
    |
    */

    'app_url' => env('APP_URL', 'https://ppmbki.ponpes.id'),

    /*
    |--------------------------------------------------------------------------
    | Force HTTPS for all Livewire requests
    |--------------------------------------------------------------------------
    */

    'https' => true,

    /*
    |--------------------------------------------------------------------------
    | Asset URL (optional, for scripts/styles)
    |--------------------------------------------------------------------------
    */

    'asset_url' => env('ASSET_URL', 'https://ppmbki.ponpes.id'),
];
