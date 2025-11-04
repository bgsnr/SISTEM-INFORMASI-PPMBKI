<?php

use Illuminate\Support\Str;

return [

    'app_url' => env('APP_URL', 'https://ppmbki.ponpes.id'),

    'https' => Str::startsWith(env('APP_URL', ''), 'https://'),

    'asset_url' => env('ASSET_URL', 'https://ppmbki.ponpes.id'),

];
