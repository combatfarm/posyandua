<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\JadwalApiController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\PerkembanganAnakApiController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// Autentikasi
Route::post('login', [AuthController::class, 'login']);
Route::post('register', [AuthController::class, 'register']);

// Route yang dilindungi middleware auth:sanctum
Route::middleware('auth:sanctum')->group(function () {
    // User info
    Route::get('user', [AuthController::class, 'user']);
    Route::post('logout', [AuthController::class, 'logout']);
    
    // Jadwal routes
    Route::prefix('jadwal')->group(function () {
        // General jadwal routes
        Route::get('/', [JadwalApiController::class, 'index']);
        Route::get('/upcoming', [JadwalApiController::class, 'upcoming']);
        Route::get('/pemeriksaan', [JadwalApiController::class, 'pemeriksaan']);
        Route::get('/imunisasi', [JadwalApiController::class, 'imunisasi']);
        Route::get('/vitamin', [JadwalApiController::class, 'vitamin']);
        Route::get('/jenis-imunisasi', [JadwalApiController::class, 'jenisImunisasi']);
        Route::get('/jenis-vitamin', [JadwalApiController::class, 'jenisVitamin']);
        
        // Age-filtered jadwal routes
        Route::get('/upcoming/anak/{id}', [JadwalApiController::class, 'upcomingForChild']);
        Route::get('/imunisasi/anak/{id}', [JadwalApiController::class, 'imunisasiForChild']);
        Route::get('/vitamin/anak/{id}', [JadwalApiController::class, 'vitaminForChild']);
        
        // Age range reference routes (for debugging)
        Route::get('/imunisasi/age-ranges', [JadwalApiController::class, 'imunisasiAgeRanges']);
        Route::get('/vitamin/age-ranges', [JadwalApiController::class, 'vitaminAgeRanges']);
        
        // Status update routes
        Route::post('/pemeriksaan/{id}/status', [JadwalApiController::class, 'updatePemeriksaanStatus']);
        Route::post('/imunisasi/{id}/status', [JadwalApiController::class, 'updateImunisasiStatus']);
        Route::post('/vitamin/{id}/status', [JadwalApiController::class, 'updateVitaminStatus']);
        
        // Check status routes
        Route::get('/imunisasi/{id}/check', [JadwalApiController::class, 'checkImunisasiStatus']);
        Route::get('/vitamin/{id}/check', [JadwalApiController::class, 'checkVitaminStatus']);
    });
    
    // Anak and other routes would go here...

    // Perkembangan Anak Routes
    Route::get('perkembangan/anak/{anakId}', [PerkembanganAnakApiController::class, 'getByAnakId']);
    Route::post('perkembangan', [PerkembanganAnakApiController::class, 'store']);
    Route::put('perkembangan/{id}', [PerkembanganAnakApiController::class, 'update']);
    Route::delete('perkembangan/{id}', [PerkembanganAnakApiController::class, 'destroy']);
}); 