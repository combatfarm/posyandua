import 'package:posyandu/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ImunisasiService {
  final ApiService _apiService = ApiService();
  
  // Singleton pattern
  static final ImunisasiService _instance = ImunisasiService._internal();
  
  factory ImunisasiService() {
    return _instance;
  }
  
  ImunisasiService._internal();

  /// Mendapatkan data anak berdasarkan ID
  Future<Map<String, dynamic>> getAnakData(int anakId) async {
    try {
      final response = await _apiService.get('anak/$anakId');
      
      // Print full response for debugging
      print('Full anak data response: $response');
      
      if (response['success'] == true && response['data'] != null) {
        print('Berhasil mendapatkan data anak dengan ID $anakId');
        return response['data'];
      } else {
        print('API mengembalikan status bukan success: ${response['success']}');
        throw Exception(response['message'] ?? 'Data anak tidak ditemukan');
      }
    } catch (e) {
      print('Error saat mengambil data anak: $e');
      throw Exception('Data anak tidak ditemukan: $e');
    }
  }

  /// Mendapatkan semua imunisasi
  Future<List<dynamic>> getAllImunisasi({Map<String, dynamic>? filters}) async {
    try {
      // Siapkan parameter query
      String endpoint = 'imunisasi';
      
      // Tambahkan filter jika ada
      if (filters != null && filters.isNotEmpty) {
        List<String> queryParams = [];
        filters.forEach((key, value) {
          if (value != null) {
            queryParams.add('$key=$value');
          }
        });
        
        if (queryParams.isNotEmpty) {
          endpoint = '$endpoint?${queryParams.join('&')}';
        }
      }
      
      final response = await _apiService.get(endpoint);
      
      if (response['status'] == 'success') {
        final imunisasiList = response['data'] as List;
        print('Berhasil mendapatkan ${imunisasiList.length} data imunisasi dari API');
        return imunisasiList;
      } else {
        print('API mengembalikan status bukan success: ${response['status']}');
        throw Exception(response['message'] ?? 'Gagal mendapatkan data imunisasi');
      }
    } catch (e) {
      print('Error saat mengambil data imunisasi: $e');
      return []; // Return empty list on error
    }
  }

  /// Mendapatkan imunisasi berdasarkan ID
  Future<Map<String, dynamic>> getImunisasiById(int id) async {
    try {
      final response = await _apiService.get('imunisasi/$id');
      
      if (response['status'] == 'success') {
        final imunisasi = response['data'] as Map<String, dynamic>;
        print('Berhasil mendapatkan data imunisasi dengan ID $id dari API');
        return imunisasi;
      } else {
        print('API mengembalikan status bukan success: ${response['status']}');
        throw Exception(response['message'] ?? 'Gagal mendapatkan data imunisasi');
      }
    } catch (e) {
      print('Error saat mengambil data imunisasi by ID: $e');
      throw Exception('Gagal memuat data imunisasi: $e');
    }
  }

  /// Mendapatkan imunisasi untuk anak tertentu
  Future<List<dynamic>> getImunisasiByAnakId(int anakId) async {
    try {
      final response = await _apiService.get('imunisasi/anak/$anakId');
      
      if (response['status'] == 'success') {
        final imunisasiList = response['data'] as List;
        print('Berhasil mendapatkan ${imunisasiList.length} data imunisasi untuk anak $anakId dari API');
        return imunisasiList;
      } else {
        print('API mengembalikan status bukan success: ${response['status']}');
        throw Exception(response['message'] ?? 'Gagal mendapatkan data imunisasi untuk anak');
      }
    } catch (e) {
      print('Error saat mengambil data imunisasi untuk anak: $e');
      return []; // Return empty list on error
    }
  }

  /// Mendapatkan jadwal imunisasi untuk anak berdasarkan usia
  Future<Map<String, dynamic>> getJadwalForAnak(int anakId) async {
    try {
      final response = await _apiService.get('imunisasi/jadwal/anak/$anakId');
      
      if (response['status'] == 'success') {
        final result = {
          'data': response['data'] as List,
          'anak': response['anak'] as Map<String, dynamic>
        };
        
        print('Berhasil mendapatkan jadwal imunisasi untuk anak $anakId (usia ${response['anak']['umur_hari']} hari)');
        return result;
      } else {
        print('API mengembalikan status bukan success: ${response['status']}');
        throw Exception(response['message'] ?? 'Gagal mendapatkan jadwal imunisasi untuk anak');
      }
    } catch (e) {
      print('Error saat mengambil jadwal imunisasi untuk anak: $e');
      return {
        'data': [],
        'anak': {}
      }; // Return empty data on error
    }
  }

  /// Mendapatkan jadwal imunisasi dengan status implementasi
  Future<List<dynamic>> getJadwalWithStatus({DateTime? startDate, DateTime? endDate}) async {
    try {
      String endpoint = 'imunisasi/jadwal/status';
      
      // Tambahkan filter date range jika ada
      if (startDate != null && endDate != null) {
        final formatter = DateFormat('yyyy-MM-dd');
        endpoint += '?start_date=${formatter.format(startDate)}&end_date=${formatter.format(endDate)}';
      }
      
      final response = await _apiService.get(endpoint);
      
      if (response['status'] == 'success') {
        final jadwalList = response['data'] as List;
        print('Berhasil mendapatkan ${jadwalList.length} jadwal imunisasi dengan status dari API');
        return jadwalList;
      } else {
        print('API mengembalikan status bukan success: ${response['status']}');
        throw Exception(response['message'] ?? 'Gagal mendapatkan jadwal imunisasi dengan status');
      }
    } catch (e) {
      print('Error saat mengambil jadwal imunisasi dengan status: $e');
      return []; // Return empty list on error
    }
  }

  /// Update status imunisasi
  Future<Map<String, dynamic>> updateImunisasiStatus(int id, String status, {DateTime? tanggal}) async {
    try {
      Map<String, dynamic> data = {'status': status};
      
      // Tambahkan tanggal jika ada
      if (tanggal != null) {
        final formatter = DateFormat('yyyy-MM-dd');
        data['tanggal'] = formatter.format(tanggal);
      }
      
      final response = await _apiService.post('imunisasi/$id', data);
      
      if (response['status'] == 'success') {
        print('Berhasil memperbarui status imunisasi dengan ID $id menjadi $status');
        return response['data'];
      } else {
        print('API mengembalikan status bukan success: ${response['status']}');
        throw Exception(response['message'] ?? 'Gagal memperbarui status imunisasi');
      }
    } catch (e) {
      print('Error saat memperbarui status imunisasi: $e');
      throw Exception('Gagal memperbarui status imunisasi: $e');
    }
  }

  /// Mendaftarkan anak untuk jadwal imunisasi
  Future<Map<String, dynamic>> registerForJadwal(int jadwalId, int anakId) async {
    try {
      Map<String, dynamic> data = {
        'jadwal_imunisasi_id': jadwalId,
        'anak_id': anakId
      };
      
      final response = await _apiService.post('imunisasi/create-from-jadwal', data);
      
      if (response['status'] == 'success') {
        print('Berhasil mendaftarkan anak untuk jadwal imunisasi');
        return response['data'];
      } else {
        print('API mengembalikan status bukan success: ${response['status']}');
        throw Exception(response['message'] ?? 'Gagal mendaftarkan anak untuk jadwal imunisasi');
      }
    } catch (e) {
      print('Error saat mendaftarkan anak untuk jadwal imunisasi: $e');
      throw Exception('Gagal mendaftarkan anak untuk jadwal imunisasi: $e');
    }
  }

  /// Mendapatkan anak yang eligible untuk jadwal imunisasi tertentu
  Future<List<dynamic>> getEligibleChildren(int jadwalId) async {
    try {
      final response = await _apiService.get('imunisasi/jadwal/$jadwalId/eligible-children');
      
      if (response['success'] == true) {
        final children = response['data'] as List;
        print('Berhasil mendapatkan ${children.length} anak yang eligible untuk jadwal imunisasi $jadwalId');
        return children;
      } else {
        print('API mengembalikan success bukan true: ${response['success']}');
        throw Exception(response['message'] ?? 'Gagal mendapatkan anak yang eligible');
      }
    } catch (e) {
      print('Error saat mengambil data anak yang eligible: $e');
      return []; // Return empty list on error
    }
  }

  /// Memeriksa status implementasi jadwal
  Future<Map<String, dynamic>> checkJadwalStatus(int jadwalId) async {
    try {
      final response = await _apiService.get('imunisasi/jadwal/$jadwalId/status');
      
      if (response['success'] == true) {
        final data = response['data'][0] as Map<String, dynamic>;
        print('Berhasil mendapatkan status implementasi jadwal imunisasi $jadwalId');
        return data;
      } else {
        print('API mengembalikan success bukan true: ${response['success']}');
        throw Exception(response['message'] ?? 'Gagal memeriksa status implementasi jadwal');
      }
    } catch (e) {
      print('Error saat memeriksa status implementasi jadwal: $e');
      throw Exception('Gagal memeriksa status implementasi jadwal: $e');
    }
  }

  /// Menandai jadwal sebagai complete dan mendaftarkan semua anak yang eligible
  Future<Map<String, dynamic>> completeJadwal(int jadwalId) async {
    try {
      final response = await _apiService.post('imunisasi/jadwal/$jadwalId/complete', {});
      
      if (response['success'] == true) {
        print('Berhasil menandai jadwal imunisasi $jadwalId sebagai selesai');
        return response['data'];
      } else {
        print('API mengembalikan success bukan true: ${response['success']}');
        throw Exception(response['message'] ?? 'Gagal menandai jadwal sebagai selesai');
      }
    } catch (e) {
      print('Error saat menandai jadwal sebagai selesai: $e');
      throw Exception('Gagal menandai jadwal sebagai selesai: $e');
    }
  }

  /// Konversi status imunisasi dari API ke tampilan di UI
  String getStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'belum':
        return 'Belum';
      case 'sudah_sesuai_jadwal':
        return 'Sudah (Sesuai Jadwal)';
      case 'sudah_tidak_sesuai_jadwal':
        return 'Sudah (Tidak Sesuai Jadwal)';
      case 'batal':
        return 'Batal';
      default:
        return status;
    }
  }

  /// Mendapatkan warna untuk status imunisasi
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'belum':
        return Colors.grey;
      case 'sudah_sesuai_jadwal':
        return Colors.green;
      case 'sudah_tidak_sesuai_jadwal':
        return Colors.orange;
      case 'batal':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  /// Mendapatkan icon untuk status imunisasi
  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'belum':
        return Icons.schedule;
      case 'sudah_sesuai_jadwal':
        return Icons.check_circle;
      case 'sudah_tidak_sesuai_jadwal':
        return Icons.check_circle_outline;
      case 'batal':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
