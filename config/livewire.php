<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Livewire Asset URL
    |--------------------------------------------------------------------------
    |
    | Gunakan ini untuk memaksa Livewire menggunakan HTTPS agar tidak terkena
    | mixed content error.
    |
    */

    'asset_url' => env('APP_URL', 'https://ppmbki.ponpes.id'),

    /*
    |--------------------------------------------------------------------------
    | Other Livewire Config (biarkan default)
    |--------------------------------------------------------------------------
    */
    'class_namespace' => 'App\\Livewire',
    'view_path' => resource_path('views/livewire'),
    'layout' => 'layouts.app',
    'temporary_file_upload' => [
        'disk' => null,
        'rules' => null,
        'directory' => null,
        'middleware' => null,
        'preview_mimes' => [
            'png',
            'gif',
            'bmp',
            'svg',
            'wav',
            'mp4',
            'mov',
            'avi',
            'wmv',
            'mp3',
            'm4a',
            'jpg',
            'jpeg',
            'pdf'
        ],
    ],
];
