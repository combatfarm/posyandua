<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\JadwalPemeriksaan;
use App\Models\JadwalImunisasi;
use App\Models\JadwalVitamin;
use App\Models\JenisImunisasi;
use App\Models\JenisVitamin;
use Carbon\Carbon;
use App\Models\Imunisasi;
use App\Models\Vitamin;
use App\Models\Anak;
use Illuminate\Support\Facades\Validator;

class JadwalApiController extends Controller
{
    /**
     * Get all schedules (combined from all types)
     */
    public function index()
    {
        $pemeriksaan = JadwalPemeriksaan::select(
                'id', 
                'judul', 
                \DB::raw("'pemeriksaan rutin' as jenis"), 
                'tanggal', 
                'waktu', 
                'created_at'
            )
            ->orderBy('tanggal', 'desc')
            ->get();
            
        $imunisasi = JadwalImunisasi::select(
                'jadwal_imunisasi.id', 
                'jenis_imunisasi.nama as judul', 
                \DB::raw("'imunisasi' as jenis"), 
                'jadwal_imunisasi.tanggal', 
                'jadwal_imunisasi.waktu', 
                'jadwal_imunisasi.created_at'
            )
            ->join('jenis_imunisasi', 'jadwal_imunisasi.jenis_imunisasi_id', '=', 'jenis_imunisasi.id')
            ->orderBy('jadwal_imunisasi.tanggal', 'desc')
            ->get();
            
        $vitamin = JadwalVitamin::select(
                'jadwal_vitamin.id', 
                'jenis_vitamin.nama as judul', 
                \DB::raw("'vitamin' as jenis"), 
                'jadwal_vitamin.tanggal', 
                'jadwal_vitamin.waktu', 
                'jadwal_vitamin.created_at'
            )
            ->join('jenis_vitamin', 'jadwal_vitamin.jenis_vitamin_id', '=', 'jenis_vitamin.id')
            ->orderBy('jadwal_vitamin.tanggal', 'desc')
            ->get();
        
        $jadwal = $pemeriksaan->concat($imunisasi)->concat($vitamin)
            ->sortByDesc('tanggal')
            ->values()
            ->all();
            
        return response()->json([
            'status' => 'success',
            'data' => $jadwal
        ]);
    }

    /**
     * Get upcoming schedules (all types)
     */
    public function upcoming()
    {
        $today = Carbon::today()->format('Y-m-d');
        
        $pemeriksaan = JadwalPemeriksaan::select(
                'id', 
                'judul', 
                \DB::raw("'pemeriksaan rutin' as jenis"), 
                'tanggal', 
                'waktu', 
                'created_at'
            )
            ->where('tanggal', '>=', $today)
            ->orderBy('tanggal', 'asc')
            ->get();
            
        $imunisasi = JadwalImunisasi::select(
                'jadwal_imunisasi.id', 
                'jenis_imunisasi.nama as judul', 
                \DB::raw("'imunisasi' as jenis"), 
                'jadwal_imunisasi.tanggal', 
                'jadwal_imunisasi.waktu', 
                'jadwal_imunisasi.created_at'
            )
            ->join('jenis_imunisasi', 'jadwal_imunisasi.jenis_imunisasi_id', '=', 'jenis_imunisasi.id')
            ->where('jadwal_imunisasi.tanggal', '>=', $today)
            ->orderBy('jadwal_imunisasi.tanggal', 'asc')
            ->get();
            
        $vitamin = JadwalVitamin::select(
                'jadwal_vitamin.id', 
                'jenis_vitamin.nama as judul', 
                \DB::raw("'vitamin' as jenis"), 
                'jadwal_vitamin.tanggal', 
                'jadwal_vitamin.waktu', 
                'jadwal_vitamin.created_at'
            )
            ->join('jenis_vitamin', 'jadwal_vitamin.jenis_vitamin_id', '=', 'jenis_vitamin.id')
            ->where('jadwal_vitamin.tanggal', '>=', $today)
            ->orderBy('jadwal_vitamin.tanggal', 'asc')
            ->get();
        
        $jadwal = $pemeriksaan->concat($imunisasi)->concat($vitamin)
            ->sortBy('tanggal')
            ->values()
            ->all();
            
        return response()->json([
            'status' => 'success',
            'data' => $jadwal
        ]);
    }
    
    /**
     * Get upcoming schedules filtered by child's age
     */
    public function upcomingForChild($anakId)
    {
        $today = Carbon::today()->format('Y-m-d');
        
        try {
            // Get child data to calculate age
            $anak = Anak::findOrFail($anakId);
            $tanggalLahir = Carbon::parse($anak->tanggal_lahir);
            $usiaBulan = Carbon::now()->diffInMonths($tanggalLahir);
            $usiaHari = Carbon::now()->diffInDays($tanggalLahir);
            
            // Log child age for debugging
            \Log::info("Anak ID: $anakId, Nama: {$anak->nama}, Tanggal Lahir: {$anak->tanggal_lahir}");
            \Log::info("Usia: $usiaBulan bulan ($usiaHari hari)");
            
            // Always include pemeriksaan rutin
            $pemeriksaan = JadwalPemeriksaan::select(
                    'id', 
                    'judul', 
                    \DB::raw("'pemeriksaan rutin' as jenis"), 
                    'tanggal', 
                    'waktu', 
                    'created_at'
                )
                ->where('tanggal', '>=', $today)
                ->orderBy('tanggal', 'asc')
                ->get();
                
            // Get imunisasi that are appropriate for child's age
            $imunisasi = $this->getAgeAppropriateImunisasi($usiaBulan, $today);
                
            // Get vitamin that are appropriate for child's age
            $vitamin = $this->getAgeAppropriateVitamin($usiaBulan, $today);
            
            $jadwal = $pemeriksaan->concat($imunisasi)->concat($vitamin)
                ->sortBy('tanggal')
                ->values()
                ->all();
            
            \Log::info("Total jadwal: " . count($jadwal) . 
                " (Pemeriksaan: " . count($pemeriksaan) . 
                ", Imunisasi: " . count($imunisasi) . 
                ", Vitamin: " . count($vitamin) . ")");
                
            return response()->json([
                'status' => 'success',
                'data' => $jadwal,
                'child_info' => [
                    'id' => $anakId,
                    'nama' => $anak->nama,
                    'tanggal_lahir' => $anak->tanggal_lahir,
                    'age_months' => $usiaBulan,
                    'age_days' => $usiaHari
                ],
                'filter_info' => [
                    'filter_applied' => true,
                    'records_found' => count($jadwal),
                    'pemeriksaan_count' => count($pemeriksaan),
                    'imunisasi_count' => count($imunisasi),
                    'vitamin_count' => count($vitamin)
                ]
            ]);
            
        } catch (\Exception $e) {
            \Log::error("Error getting age-appropriate schedules: " . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to get age-appropriate schedules: ' . $e->getMessage(),
                'debug_trace' => $e->getTraceAsString()
            ], 500);
        }
    }
    
    /**
     * Get imunisasi schedules filtered by child's age
     */
    public function imunisasiForChild($anakId)
    {
        $today = Carbon::today()->format('Y-m-d');
        
        try {
            // Get child data to calculate age
            $anak = Anak::findOrFail($anakId);
            $tanggalLahir = Carbon::parse($anak->tanggal_lahir);
            $usiaBulan = Carbon::now()->diffInMonths($tanggalLahir);
            
            // Log child age for debugging
            \Log::info("Anak ID: $anakId, Nama: {$anak->nama}, Tanggal Lahir: {$anak->tanggal_lahir}, Usia: $usiaBulan bulan");
            
            // Get imunisasi that are appropriate for child's age
            $jadwal = $this->getAgeAppropriateImunisasi($usiaBulan, $today);
                
            return response()->json([
                'status' => 'success',
                'data' => $jadwal,
                'child_info' => [
                    'id' => $anakId,
                    'nama' => $anak->nama,
                    'tanggal_lahir' => $anak->tanggal_lahir,
                    'age_months' => $usiaBulan
                ],
                'filter_info' => [
                    'filter_applied' => true,
                    'records_found' => count($jadwal)
                ]
            ]);
            
        } catch (\Exception $e) {
            \Log::error("Error getting age-appropriate imunisasi: " . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to get age-appropriate imunisasi: ' . $e->getMessage(),
                'debug_trace' => $e->getTraceAsString()
            ], 500);
        }
    }
    
    /**
     * Get vitamin schedules filtered by child's age
     */
    public function vitaminForChild($anakId)
    {
        $today = Carbon::today()->format('Y-m-d');
        
        try {
            // Get child data to calculate age
            $anak = Anak::findOrFail($anakId);
            $tanggalLahir = Carbon::parse($anak->tanggal_lahir);
            $usiaBulan = Carbon::now()->diffInMonths($tanggalLahir);
            
            // Log child age for debugging
            \Log::info("Anak ID: $anakId, Nama: {$anak->nama}, Tanggal Lahir: {$anak->tanggal_lahir}, Usia: $usiaBulan bulan");
            
            // Get vitamin that are appropriate for child's age
            $jadwal = $this->getAgeAppropriateVitamin($usiaBulan, $today);
                
            return response()->json([
                'status' => 'success',
                'data' => $jadwal,
                'child_info' => [
                    'id' => $anakId,
                    'nama' => $anak->nama,
                    'tanggal_lahir' => $anak->tanggal_lahir,
                    'age_months' => $usiaBulan
                ],
                'filter_info' => [
                    'filter_applied' => true,
                    'records_found' => count($jadwal)
                ]
            ]);
            
        } catch (\Exception $e) {
            \Log::error("Error getting age-appropriate vitamin: " . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to get age-appropriate vitamin: ' . $e->getMessage(),
                'debug_trace' => $e->getTraceAsString()
            ], 500);
        }
    }
    
    /**
     * Helper method to get age-appropriate imunisasi
     */
    private function getAgeAppropriateImunisasi($usiaBulan, $today)
    {
        // Konversi usia bulan ke hari untuk imunisasi
        $usiaHari = $usiaBulan * 30; // Perkiraan kasar 1 bulan = 30 hari
        
        // Filter imunisasi berdasarkan data di database sesuai dengan umur dalam hari
        $ageRanges = [
            'HB-0' => [0, 7],                          // 0-7 hari
            'BCG' => [0, 30],                          // 0-30 hari (1 bulan)
            'Polio 1' => [0, 30],                      // 0-30 hari (1 bulan)
            'DPT-HB-HIP 1' => [0, 60],                 // 0-60 hari (2 bulan)
            'Polio 2' => [0, 60],                      // 0-60 hari (2 bulan)
            'DPT-HB-HIP 2' => [0, 90],                 // 0-90 hari (3 bulan)
            'Polio 3' => [0, 90],                      // 0-90 hari (3 bulan)
            'DPT-HB-HIP 3' => [0, 120],                // 0-120 hari (4 bulan)
            'Polio 4' => [0, 120],                     // 0-120 hari (4 bulan)
            'Campak' => [0, 270],                      // 0-270 hari (9 bulan)
        ];
        
        // Base query untuk semua jadwal imunisasi yang akan datang
        $query = JadwalImunisasi::select(
                'jadwal_imunisasi.id', 
                'jenis_imunisasi.nama as judul', 
                \DB::raw("'imunisasi' as jenis"), 
                'jadwal_imunisasi.tanggal', 
                'jadwal_imunisasi.waktu', 
                'jadwal_imunisasi.created_at'
            )
            ->join('jenis_imunisasi', 'jadwal_imunisasi.jenis_imunisasi_id', '=', 'jenis_imunisasi.id')
            ->where('jadwal_imunisasi.tanggal', '>=', $today)
            ->orderBy('jadwal_imunisasi.tanggal', 'asc');
            
        // Add age filtering - we'll use a different approach to ensure strict filtering
        if ($usiaHari !== null) {
            // Start with an impossible condition to build "OR" conditions
            $matchedAny = false;
            $query->where(function($q) use ($ageRanges, $usiaHari, &$matchedAny) {
                foreach ($ageRanges as $imunisasiName => [$minAge, $maxAge]) {
                    if ($usiaHari >= $minAge && $usiaHari <= $maxAge) {
                        if ($matchedAny) {
                            $q->orWhere('jenis_imunisasi.nama', 'like', "%$imunisasiName%");
                        } else {
                            $q->where('jenis_imunisasi.nama', 'like', "%$imunisasiName%");
                            $matchedAny = true;
                        }
                    }
                }
                
                // If no matches, ensure no results are returned
                if (!$matchedAny) {
                    $q->where('jenis_imunisasi.id', 0); // This will ensure no results
                }
            });
        }
        
        // Log the SQL query for debugging
        \Log::info('Imunisasi SQL query: ' . $query->toSql());
        \Log::info('Imunisasi query bindings: ' . json_encode($query->getBindings()));
        \Log::info('Usia anak dalam hari: ' . $usiaHari);
        
        $results = $query->get();
        
        // Log the results
        \Log::info('Imunisasi results: ' . $results->count() . ' records found for age ' . $usiaBulan . ' months (' . $usiaHari . ' days)');
        
        return $results;
    }
    
    /**
     * Helper method to get age-appropriate vitamin
     */
    private function getAgeAppropriateVitamin($usiaBulan, $today)
    {
        // Filter vitamin berdasarkan data di database
        $ageRanges = [
            'A Biru' => [6, 11],        // 6-11 bulan
            'A Merah' => [12, 59],      // 12-59 bulan
        ];
        
        // Base query for all upcoming vitamin
        $query = JadwalVitamin::select(
                'jadwal_vitamin.id', 
                'jenis_vitamin.nama as judul', 
                \DB::raw("'vitamin' as jenis"), 
                'jadwal_vitamin.tanggal', 
                'jadwal_vitamin.waktu', 
                'jadwal_vitamin.created_at'
            )
            ->join('jenis_vitamin', 'jadwal_vitamin.jenis_vitamin_id', '=', 'jenis_vitamin.id')
            ->where('jadwal_vitamin.tanggal', '>=', $today)
            ->orderBy('jadwal_vitamin.tanggal', 'asc');
            
        // Add age filtering - we'll use a different approach to ensure strict filtering
        if ($usiaBulan !== null) {
            // Start with an impossible condition to build "OR" conditions
            $matchedAny = false;
            $query->where(function($q) use ($ageRanges, $usiaBulan, &$matchedAny) {
                foreach ($ageRanges as $vitaminName => [$minAge, $maxAge]) {
                    if ($usiaBulan >= $minAge && $usiaBulan <= $maxAge) {
                        if ($matchedAny) {
                            $q->orWhere('jenis_vitamin.nama', 'like', "%$vitaminName%");
                        } else {
                            $q->where('jenis_vitamin.nama', 'like', "%$vitaminName%");
                            $matchedAny = true;
                        }
                    }
                }
                
                // If no matches, ensure no results are returned
                if (!$matchedAny) {
                    $q->where('jenis_vitamin.id', 0); // This will ensure no results
                }
            });
        }
        
        // Log the SQL query for debugging
        \Log::info('Vitamin SQL query: ' . $query->toSql());
        \Log::info('Vitamin query bindings: ' . json_encode($query->getBindings()));
        \Log::info('Usia anak dalam bulan: ' . $usiaBulan);
        
        $results = $query->get();
        
        // Log the results
        \Log::info('Vitamin results: ' . $results->count() . ' records found for age ' . $usiaBulan . ' months');
        
        return $results;
    }

    /**
     * Get pemeriksaan schedules
     */
    public function pemeriksaan()
    {
// ... existing code ...
    }

    /**
     * Get list of immunization types with age ranges
     */
    public function imunisasiAgeRanges()
    {
        $ageRanges = [
            'HB-0' => [0, 7],                          // 0-7 hari
            'BCG' => [0, 30],                          // 0-30 hari (1 bulan)
            'Polio 1' => [0, 30],                      // 0-30 hari (1 bulan)
            'DPT-HB-HIP 1' => [0, 60],                 // 0-60 hari (2 bulan)
            'Polio 2' => [0, 60],                      // 0-60 hari (2 bulan)
            'DPT-HB-HIP 2' => [0, 90],                 // 0-90 hari (3 bulan)
            'Polio 3' => [0, 90],                      // 0-90 hari (3 bulan)
            'DPT-HB-HIP 3' => [0, 120],                // 0-120 hari (4 bulan)
            'Polio 4' => [0, 120],                     // 0-120 hari (4 bulan)
            'Campak' => [0, 270],                      // 0-270 hari (9 bulan)
        ];
        
        $formattedRanges = [];
        foreach ($ageRanges as $name => $range) {
            // Convert days to months for display (approximate)
            $minMonths = floor($range[0] / 30);
            $minDays = $range[0] % 30;
            $maxMonths = floor($range[1] / 30);
            $maxDays = $range[1] % 30;
            
            $minAgeText = $minMonths > 0 ? "$minMonths bulan " : "";
            $minAgeText .= $minDays > 0 ? "$minDays hari" : "";
            $minAgeText = $minAgeText ?: "0 hari";
            
            $maxAgeText = $maxMonths > 0 ? "$maxMonths bulan " : "";
            $maxAgeText .= $maxDays > 0 ? "$maxDays hari" : "";
            $maxAgeText = $maxAgeText ?: "0 hari";
            
            $formattedRanges[] = [
                'nama' => $name,
                'usia_min_hari' => $range[0],
                'usia_max_hari' => $range[1],
                'usia_min_text' => $minAgeText,
                'usia_max_text' => $maxAgeText,
                'deskripsi' => "Untuk anak usia {$minAgeText} sampai {$maxAgeText}"
            ];
        }
        
        return response()->json([
            'status' => 'success',
            'data' => $formattedRanges
        ]);
    }
    
    /**
     * Get list of vitamin types with age ranges
     */
    public function vitaminAgeRanges()
    {
        $ageRanges = [
            'A Biru' => [6, 11],        // 6-11 bulan
            'A Merah' => [12, 59],      // 12-59 bulan
        ];
        
        $formattedRanges = [];
        foreach ($ageRanges as $name => $range) {
            $formattedRanges[] = [
                'nama' => $name,
                'usia_min_bulan' => $range[0],
                'usia_max_bulan' => $range[1],
                'deskripsi' => "Untuk anak usia {$range[0]}-{$range[1]} bulan"
            ];
        }
        
        return response()->json([
            'status' => 'success',
            'data' => $formattedRanges
        ]);
    }
} 