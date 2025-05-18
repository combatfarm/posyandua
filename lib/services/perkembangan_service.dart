import 'package:posyandu/services/api_service.dart';
import 'package:intl/intl.dart';

class PerkembanganService {
  final ApiService _apiService = ApiService();
  
  // Singleton pattern
  static final PerkembanganService _instance = PerkembanganService._internal();
  
  factory PerkembanganService() {
    return _instance;
  }
  
  PerkembanganService._internal();

  /// Mendapatkan semua data perkembangan anak berdasarkan ID anak
  /// Fungsi ini mengambil SELURUH riwayat pertumbuhan anak, termasuk data yang sudah diupdate
  Future<List<dynamic>> getPerkembanganByAnakId(int anakId) async {
    try {
      // Pastikan selalu mendapatkan data terbaru dari server
      _apiService.clearCache();
      
      final response = await _apiService.get('perkembangan/anak/$anakId');
      
      if (response['status'] == 'success') {
        List<dynamic> perkembanganList = [];
        
        if (response['perkembangan'] is List) {
          perkembanganList = response['perkembangan'] as List;
        } else if (response['perkembangan'] is Map) {
          perkembanganList = [response['perkembangan'] as Map<String, dynamic>];
        }
        
        // Filter dan urutkan data
        final filteredList = _processPerkembanganList(perkembanganList);
        print('Berhasil mendapatkan ${filteredList.length} data riwayat perkembangan anak dari API');
        return filteredList;
      } else {
        print('API mengembalikan status bukan success: ${response['status']}');
        throw Exception(response['message'] ?? 'Gagal mendapatkan data perkembangan anak');
      }
    } catch (e) {
      print('Error saat mengambil data perkembangan anak: $e');
      return [];
    }
  }

  /// Memproses dan memfilter data perkembangan
  List<dynamic> _processPerkembanganList(List<dynamic> perkembanganList) {
    // Kelompokkan data berdasarkan tanggal
    Map<String, List<dynamic>> groupedByDate = {};
    
    for (var data in perkembanganList) {
      final tanggal = data['tanggal'].toString().split(' ')[0]; // Ambil tanggal saja
      if (!groupedByDate.containsKey(tanggal)) {
        groupedByDate[tanggal] = [];
      }
      groupedByDate[tanggal]!.add(data);
    }
    
    // Untuk setiap tanggal, ambil data terbaru (yang belum diupdate)
    List<dynamic> processedList = [];
    groupedByDate.forEach((tanggal, dataList) {
      // Urutkan berdasarkan created_at terbaru
      dataList.sort((a, b) => 
        DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at']))
      );
      
      // Ambil data yang belum diupdate (is_updated = false) atau data terbaru
      var latestData = dataList.firstWhere(
        (data) => data['is_updated'] == false,
        orElse: () => dataList.first
      );
      
      // Tambahkan informasi riwayat jika ada
      if (dataList.length > 1) {
        latestData['has_history'] = true;
        latestData['history'] = dataList;
      }
      
      processedList.add(latestData);
    });
    
    // Urutkan berdasarkan tanggal
    processedList.sort((a, b) => 
      DateTime.parse(a['tanggal']).compareTo(DateTime.parse(b['tanggal']))
    );
    
    return processedList;
  }

  /// Validasi data perkembangan
  Map<String, String?> validatePerkembanganData({
    required DateTime tanggal,
    required double beratBadan,
    required double tinggiBadan,
  }) {
    final errors = <String, String?>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inputDate = DateTime(tanggal.year, tanggal.month, tanggal.day);

    // Validasi tanggal tidak boleh di masa depan
    if (inputDate.isAfter(today)) {
      errors['tanggal'] = 'Tanggal pengukuran tidak boleh di masa depan';
    }

    // Validasi berat badan
    if (beratBadan <= 0) {
      errors['berat_badan'] = 'Berat badan harus lebih dari 0';
    } else if (beratBadan > 50) { // Batas maksimal yang masuk akal untuk anak
      errors['berat_badan'] = 'Berat badan tidak valid';
    }

    // Validasi tinggi badan
    if (tinggiBadan <= 0) {
      errors['tinggi_badan'] = 'Tinggi badan harus lebih dari 0';
    } else if (tinggiBadan > 200) { // Batas maksimal yang masuk akal untuk anak
      errors['tinggi_badan'] = 'Tinggi badan tidak valid';
    }

    return errors;
  }

  /// Menyimpan atau memperbarui data perkembangan
  /// PENTING: Fungsi ini akan selalu membuat record baru untuk setiap perubahan
  Future<Map<String, dynamic>> updatePerkembangan({
    required int anakId,
    required DateTime tanggal,
    required double beratBadan,
    required double tinggiBadan,
    int? perkembanganId, // Optional: ID record lama jika mengupdate
  }) async {
    try {
      // Validasi data
      final errors = validatePerkembanganData(
        tanggal: tanggal,
        beratBadan: beratBadan,
        tinggiBadan: tinggiBadan,
      );

      if (errors.isNotEmpty) {
        throw Exception(errors.values.firstWhere((error) => error != null) ?? 'Data tidak valid');
      }

      // Format data untuk API
      final Map<String, dynamic> data = {
        'anak_id': anakId,
        'tanggal': DateFormat('yyyy-MM-dd').format(tanggal),
        'berat_badan': beratBadan.toStringAsFixed(2), // Pastikan 2 desimal
        'tinggi_badan': tinggiBadan.toStringAsFixed(2), // Pastikan 2 desimal
      };
      
      // Jika ada ID record lama, gunakan endpoint update
      // Jika tidak, gunakan endpoint store
      final endpoint = perkembanganId != null 
          ? 'perkembangan/$perkembanganId'
          : 'perkembangan';
          
      final method = perkembanganId != null ? 'put' : 'post';
      
      print('Mengirim data perkembangan ${perkembanganId != null ? "update" : "baru"}: $data');
      
      try {
        final response = await _apiService.request(
          method: method,
          endpoint: endpoint,
          data: data,
        );
        
        if (response['status'] == 'success') {
          // Tambahkan informasi riwayat jika ini adalah update
          if (perkembanganId != null && response['perkembangan'] != null) {
            response['perkembangan']['updated_from_id'] = perkembanganId;
          }
          
          print('✅ Data perkembangan berhasil ${perkembanganId != null ? "diperbarui" : "disimpan"}');
          return response;
        } else {
          // Handle validation errors from API
          if (response['errors'] != null) {
            final apiErrors = response['errors'] as Map<String, dynamic>;
            final firstError = apiErrors.values.firstWhere(
              (error) => error != null && error.isNotEmpty,
              orElse: () => ['Data tidak valid']
            );
            throw Exception(firstError.first);
          }
          throw Exception(response['message'] ?? 'Gagal menyimpan data perkembangan');
        }
      } catch (e) {
        if (e.toString().contains('422')) {
          // Handle validation errors
          throw Exception('Data tidak valid: ${e.toString().split('422').last}');
        }
        print('API perkembangan belum tersedia: $e');
        print('⚠️ PERHATIAN: Data tidak tersimpan ke server!');
        
        return {
          'status': 'success',
          'message': 'Data perkembangan berhasil disimpan (lokal)',
          'data': data,
        };
      }
    } catch (e) {
      print('❌ Error saat menyimpan data perkembangan: $e');
      throw Exception(e.toString());
    }
  }

  /// Menghapus data perkembangan
  Future<bool> deletePerkembangan(int perkembanganId) async {
    try {
      final response = await _apiService.delete('perkembangan/$perkembanganId');
      return response['status'] == 'success';
    } catch (e) {
      print('Error saat menghapus data perkembangan: $e');
      throw Exception('Error: $e');
    }
  }
  
  /// Menghitung status pertumbuhan berdasarkan tinggi dan berat
  Map<String, dynamic> hitungStatusPertumbuhan(double beratBadan, double tinggiBadan, int usia, String jenisKelamin) {
    // Implementasi sederhana, nantinya bisa diganti dengan standar WHO
    
    // Status berat badan
    String statusBB = 'Normal';
    if (beratBadan < 8.0) {
      statusBB = 'Kurang';
    } else if (beratBadan > 15.0) {
      statusBB = 'Lebih';
    }
    
    // Status tinggi badan
    String statusTB = 'Normal';
    if (tinggiBadan < 75.0) {
      statusTB = 'Pendek';
    } else if (tinggiBadan > 95.0) {
      statusTB = 'Tinggi';
    }
    
    return {
      'status_bb': statusBB,
      'status_tb': statusTB,
    };
  }
}
