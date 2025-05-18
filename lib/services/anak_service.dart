import 'package:posyandu/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AnakService {
  final ApiService _apiService = ApiService();
  
  // Singleton pattern
  static final AnakService _instance = AnakService._internal();
  
  factory AnakService() {
    return _instance;
  }
  
  AnakService._internal();

  /// Mendapatkan daftar anak milik pengguna yang sedang login
  Future<List<dynamic>> getAnakList() async {
    try {
      // Dapatkan user_id dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      if (userId != null) {
        // Gunakan endpoint dari Laravel controller
        // Perhatikan bahwa model pengguna sudah di-load dengan eager loading (with('pengguna'))
        final response = await _apiService.get('anak');
        
        if (response['success'] == true) {
          final anakList = response['data'] ?? [];
          print('Berhasil mendapatkan ${anakList.length} data anak');
          
          // Debug: periksa apakah data pengguna (parent) sudah masuk
          if (anakList.isNotEmpty) {
            print('Sample anak data: ${anakList[0]}');
            if (anakList[0]['pengguna'] != null) {
              print('Pengguna data available: ${anakList[0]['pengguna']}');
            } else {
              print('Pengguna data not available in response');
              
              // Jika data anak tidak berisi data pengguna, coba ambil data parent secara terpisah
              try {
                // Ambil data pengguna dari ID pertama
                if (anakList.isNotEmpty && anakList[0]['pengguna_id'] != null) {
                  final penggunaId = anakList[0]['pengguna_id'];
                  final penggunaData = await getPenggunaById(penggunaId);
                  print('Berhasil mendapatkan data parent: $penggunaData');
                  
                  // Simpan ke SharedPreferences untuk digunakan di seluruh aplikasi
                  if (penggunaData != null) {
                    await prefs.setString('nik', penggunaData['nik'] ?? '');
                    await prefs.setString('nama_ibu', penggunaData['nama'] ?? '');
                    print('Data parent disimpan ke SharedPreferences');
                  }
                }
              } catch (e) {
                print('Gagal mendapatkan data parent: $e');
              }
            }
          }
          
          return anakList;
        } else {
          throw Exception(response['message'] ?? 'Gagal mendapatkan data anak');
        }
      } else {
        throw Exception('User ID tidak ditemukan. Silakan login terlebih dahulu.');
      }
    } catch (e) {
      print('Error saat mengambil data anak: $e');
      throw Exception('Error: $e');
    }
  }

  /// Mendapatkan detail data anak berdasarkan ID
  Future<Map<String, dynamic>> getAnakDetail(int anakId) async {
    try {
      // Endpoint sudah menggunakan with('pengguna') di Laravel
      final response = await _apiService.get('anak/$anakId');
      
      if (response['success'] == true) {
        final anakData = response['data'];
        print('Detail anak: $anakData');
        
        return anakData;
      } else {
        throw Exception(response['message'] ?? 'Gagal mendapatkan detail anak');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Menambahkan data anak baru
  Future<Map<String, dynamic>> createAnak({
    required String namaAnak,
    required String tempatLahir,
    required DateTime tanggalLahir,
    required String jenisKelamin,
  }) async {
    try {
      // Dapatkan ID pengguna dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id'); // Pastikan menyimpan sebagai int
      
      print('UserId from SharedPreferences: $userId');
      
      int? penggunaId;
      
      // Jika user_id tidak ada, coba dapatkan dari user endpoint
      if (userId == null) {
        try {
          // Menggunakan /api/user endpoint untuk mendapatkan data user yang terautentikasi
          final userData = await _apiService.get('user');
          print('User data response: $userData');
          
          if (userData['success'] == true && userData['pengguna'] != null) {
            penggunaId = userData['pengguna']['id'];
            // Simpan user_id untuk penggunaan selanjutnya
            await prefs.setInt('user_id', penggunaId!);
            print('ID pengguna berhasil didapatkan dari API: $penggunaId');
          } else {
            throw Exception('Gagal mendapatkan data pengguna dari API');
          }
        } catch (e) {
          print('Gagal mendapatkan data pengguna: $e');
          throw Exception('Gagal mendapatkan ID pengguna, pastikan Anda sudah login');
        }
      } else {
        penggunaId = userId;
      }
      
      // Hitung usia dalam bulan dan hari
      String usia = _calculateAge(tanggalLahir);
      
      // Format data untuk API
      final Map<String, dynamic> data = {
        'pengguna_id': penggunaId,
        'nama_anak': namaAnak,
        'tempat_lahir': tempatLahir,
        'tanggal_lahir': DateFormat('yyyy-MM-dd').format(tanggalLahir),
        'jenis_kelamin': jenisKelamin,
        'usia': usia,
      };
      
      print('Mengirim data anak: $data');
      
      final response = await _apiService.post('anak', data);
      
      if (response['success'] == true) {
        return response;
      } else {
        throw Exception(response['message'] ?? 'Gagal menyimpan data anak');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Memperbarui data anak yang sudah ada
  Future<Map<String, dynamic>> updateAnak({
    required int anakId,
    required String namaAnak,
    required String tempatLahir,
    required DateTime tanggalLahir,
    required String jenisKelamin,
  }) async {
    try {
      // Dapatkan ID pengguna dari SharedPreferences untuk logging
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      print('Updating anak with ID: $anakId by user ID: $userId');
      
      // Hitung usia dalam bulan dan hari
      String usia = _calculateAge(tanggalLahir);
      
      // Format data untuk API
      final Map<String, dynamic> data = {
        'nama_anak': namaAnak,
        'tempat_lahir': tempatLahir,
        'tanggal_lahir': DateFormat('yyyy-MM-dd').format(tanggalLahir),
        'jenis_kelamin': jenisKelamin,
        'usia': usia,
      };
      
      final response = await _apiService.put('anak/$anakId', data);
      
      if (response['success'] == true) {
        return response;
      } else {
        throw Exception(response['message'] ?? 'Gagal memperbarui data anak');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Menghapus data anak
  Future<bool> deleteAnak(int anakId) async {
    try {
      await _apiService.delete('anak/$anakId');
      return true;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
  
  /// Mengaitkan anak dengan orang tua berdasarkan NIK
  Future<Map<String, dynamic>> linkAnakToParent({
    required int anakId,
    required String nik,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'anak_id': anakId,
        'nik': nik,
      };
      
      final response = await _apiService.post('anak/link-to-parent', data);
      
      if (response['success'] == true) {
        return response;
      } else {
        throw Exception(response['message'] ?? 'Gagal mengaitkan anak dengan orang tua');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
  
  /// Fungsi untuk menghitung usia dalam bulan dari tanggal lahir
  String _calculateAge(DateTime birthDate) {
    DateTime currentDate = DateTime.now();
    
    // Hitung total usia dalam hari
    int totalDays = currentDate.difference(birthDate).inDays;
    
    // Konversi ke bulan dan hari
    int months = totalDays ~/ 30; // Aproximasi 1 bulan = 30 hari
    int days = totalDays % 30;
    
    return '$months bulan $days hari'; // Return format bulan dan hari
  }

  /// Memperbaiki data ibu yang kosong
  Future<void> fixParentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nik = prefs.getString('nik');
      final namaIbu = prefs.getString('nama_ibu');
      
      // Jika nama ibu kosong tapi NIK ada, coba dapatkan dari API
      if ((namaIbu == null || namaIbu.isEmpty) && nik != null && nik.isNotEmpty) {
        print('Nama ibu kosong, mencoba dapatkan dari API berdasarkan NIK: $nik');
        
        try {
          // Coba cari pengguna berdasarkan NIK
          final response = await _apiService.get('user');
          
          if (response['success'] == true || response['status'] == 'success') {
            final pengguna = response['pengguna'] ?? response['data'];
            if (pengguna != null) {
              // Nama bisa berupa nama atau nama_ibu
              final nama = pengguna['nama'] ?? pengguna['nama_ibu'] ?? 'Ibu';
              
              // Update SharedPreferences
              await prefs.setString('nama_ibu', nama);
              print('Berhasil update nama ibu: $nama');
              
              // Juga update NIK jika kosong
              if (nik.isEmpty && pengguna.containsKey('nik')) {
                await prefs.setString('nik', pengguna['nik']);
              }
              
              // Juga update user_id jika belum ada
              if (pengguna.containsKey('id') && prefs.getInt('user_id') == null) {
                await prefs.setInt('user_id', pengguna['id']);
              }
            }
          }
        } catch (e) {
          print('Gagal mendapatkan data ibu dari API: $e');
          
          // Fallback: gunakan default jika masih kosong
          if (namaIbu == null || namaIbu.isEmpty) {
            await prefs.setString('nama_ibu', 'Ibu');
            print('Menggunakan nama default: Ibu');
          }
        }
      } else if (namaIbu == null || namaIbu.isEmpty) {
        // Jika nama ibu masih kosong, tetapkan ke "Ibu"
        await prefs.setString('nama_ibu', 'Ibu');
        print('Menggunakan nama default: Ibu karena nama_ibu kosong');
      }
    } catch (e) {
      print('Error saat memperbaiki data ibu: $e');
    }
  }

  /// Mendapatkan data pengguna (parent) dari SharedPreferences
  Future<Map<String, dynamic>> getParentFromPrefs() async {
    try {
      // Coba perbaiki data yang kosong terlebih dahulu
      await fixParentData();
      
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final nik = prefs.getString('nik') ?? 'Tidak tersedia';
      final namaIbu = prefs.getString('nama_ibu') ?? 'Ibu';
      
      print('Data parent dari SharedPreferences setelah perbaikan: userId=$userId, nik=$nik, nama=$namaIbu');
      
      // Pastikan namaIbu tidak kosong
      if (namaIbu.isEmpty) {
        await prefs.setString('nama_ibu', 'Ibu');
      }
      
      return {
        'id': userId ?? 0,
        'nik': nik,
        'nama': namaIbu.isEmpty ? 'Ibu' : namaIbu,
      };
    } catch (e) {
      print('Error mendapatkan data parent dari SharedPreferences: $e');
      return {
        'id': 0,
        'nik': 'Tidak tersedia',
        'nama': 'Ibu',
      };
    }
  }

  /// Mendapatkan data pengguna berdasarkan ID
  Future<Map<String, dynamic>?> getPenggunaById(int penggunaId) async {
    try {
      // Ubah endpoint dari pengguna/{id} menjadi pengguna/detail/{id}
      // Sesuaikan dengan path yang benar dari Laravel API
      print('Mencoba mendapatkan data pengguna dengan ID: $penggunaId');
      
      // Coba langsung endpoint user yang sudah terbukti berfungsi
      try {
        print('Menggunakan endpoint user untuk mendapatkan data pengguna');
        final response = await _apiService.get('user');
        
        if (response['success'] == true || response['status'] == 'success') {
          // Data pengguna mungkin berada di 'pengguna' atau 'data'
          final penggunaData = response['pengguna'] ?? response['data'];
          
          if (penggunaData != null) {
            print('Response pengguna dari endpoint user: $penggunaData');
            
            // Normalkan nama field yang berbeda-beda
            // Field nama bisa berupa 'nama' atau 'nama_ibu'
            final Map<String, dynamic> normalizedData = {
              'id': penggunaData['id'],
              'nik': penggunaData['nik'],
              'nama': penggunaData['nama'] ?? penggunaData['nama_ibu'] ?? 'Ibu',
            };
            
            print('Data pengguna yang dinormalisasi: $normalizedData');
            return normalizedData;
          }
        }
      } catch (e) {
        print('Error saat mengakses endpoint user: $e');
      }
      
      // Endpoint alternatif jika user tidak berhasil
      print('Tidak bisa mendapatkan data pengguna dari endpoint utama, mencoba alternatif');
      
      // Coba gunakan beberapa alternatif endpoint
      final endpoints = [
        'pengguna/detail/$penggunaId',
        'user/profile', 
        'profile'
      ];
      
      for (String endpoint in endpoints) {
        try {
          print('Mencoba endpoint: $endpoint');
          final response = await _apiService.get(endpoint);
          
          if (response['success'] == true || response['status'] == 'success') {
            // Data pengguna mungkin berada di 'pengguna' atau 'data'
            final penggunaData = response['pengguna'] ?? response['data'];
            
            if (penggunaData != null) {
              print('Berhasil mendapatkan data pengguna dari endpoint $endpoint: $penggunaData');
              
              // Normalkan nama field
              final Map<String, dynamic> normalizedData = {
                'id': penggunaData['id'],
                'nik': penggunaData['nik'],
                'nama': penggunaData['nama'] ?? penggunaData['nama_ibu'] ?? 'Ibu',
              };
              
              return normalizedData;
            }
          }
        } catch (e) {
          print('Endpoint $endpoint error: $e');
          continue;
        }
      }
      
      print('Semua endpoint gagal, gunakan default data');
      // Return default data jika tidak bisa mendapatkan dari server
      return {
        'id': penggunaId,
        'nik': 'Data tidak tersedia',
        'nama': 'Ibu', // Default ke 'Ibu' bukan 'Data tidak tersedia'
      };
    } catch (e) {
      print('Error mendapatkan data pengguna: $e');
      return {
        'id': penggunaId,
        'nik': 'Data tidak tersedia',
        'nama': 'Ibu', // Default ke 'Ibu'
      };
    }
  }

  /// Mendapatkan detail pengguna berdasarkan ID
  Future<Map<String, dynamic>> getPenggunaDetail(int penggunaId) async {
    try {
      // Coba gunakan method getPenggunaById yang lebih robust
      Map<String, dynamic>? data = await getPenggunaById(penggunaId);
      
      if (data != null) {
        return data;
      }
      
      // Fallback jika gagal
      return {
        'id': penggunaId,
        'nama': 'Data tidak tersedia',
        'nik': 'Data tidak tersedia',
      };
    } catch (e) {
      print('Error mendapatkan detail pengguna: $e');
      // Return minimal data jika gagal
      return {
        'id': penggunaId,
        'nama': 'Data tidak tersedia',
        'nik': 'Data tidak tersedia',
      };
    }
  }
}
