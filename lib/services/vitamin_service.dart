import 'package:posyandu/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VitaminService {
  final ApiService _apiService = ApiService();
  
  // Singleton pattern
  static final VitaminService _instance = VitaminService._internal();
  
  factory VitaminService() {
    return _instance;
  }
  
  VitaminService._internal();

  /// Mendapatkan data anak berdasarkan ID
  Future<Map<String, dynamic>> getAnakData(int anakId) async {
    try {
      final response = await _apiService.get('anak/$anakId');
      
      // Handle error responses consistently
      if (response['success'] == false || response['status'] == 'error') {
        String errorMsg = response['message'] ?? 'Data anak tidak ditemukan';
        print('API anak mengembalikan error: $errorMsg');
        
        if (errorMsg.contains('tidak ditemukan')) {
          throw Exception('Data anak tidak ditemukan');
        }
        
        throw Exception(errorMsg);
      }
      
      if (response['success'] == true && response['data'] != null) {
        print('Berhasil mendapatkan data anak dengan ID $anakId');
        return response['data'];
      } else {
        print('API anak mengembalikan struktur tidak terduga: $response');
        throw Exception('Data anak tidak ditemukan');
      }
    } catch (e) {
      print('Error saat mengambil data anak: $e');
      if (e.toString().contains('Data anak tidak ditemukan')) {
        throw Exception('Data anak tidak ditemukan');
      }
      throw Exception('Data anak tidak ditemukan: $e');
    }
  }

  /// Mendapatkan semua data vitamin
  Future<List<dynamic>> getAllVitamin({Map<String, dynamic>? filters}) async {
    try {
      // Siapkan parameter query
      String endpoint = 'vitamin';
      
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
        final vitaminList = response['data'] as List;
        print('Berhasil mendapatkan ${vitaminList.length} data vitamin dari API');
        return vitaminList;
      } else {
        print('API mengembalikan status bukan success: ${response['status']}');
        throw Exception(response['message'] ?? 'Gagal mendapatkan data vitamin');
      }
    } catch (e) {
      print('Error saat mengambil data vitamin: $e');
      return []; // Return empty list on error
    }
  }

  /// Mendapatkan vitamin berdasarkan ID
  Future<Map<String, dynamic>> getVitaminById(int id) async {
    try {
      final response = await _apiService.get('vitamin/$id');
      
      if (response['status'] == 'success') {
        final vitamin = response['data'] as Map<String, dynamic>;
        print('Berhasil mendapatkan data vitamin dengan ID $id dari API');
        return vitamin;
      } else {
        print('API mengembalikan status bukan success: ${response['status']}');
        throw Exception(response['message'] ?? 'Gagal mendapatkan data vitamin');
      }
    } catch (e) {
      print('Error saat mengambil data vitamin by ID: $e');
      throw Exception('Gagal memuat data vitamin: $e');
    }
  }

  /// Mendapatkan vitamin untuk anak tertentu
  Future<List<dynamic>> getVitaminByAnakId(int anakId) async {
    try {
      final response = await _apiService.get('vitamin/anak/$anakId');
      
      // Handle error responses more consistently
      if (response['status'] == 'error' || response['status'] == false || response['success'] == false) {
        String errorMsg = response['message'] ?? 'Gagal mendapatkan data vitamin untuk anak';
        print('API mengembalikan error: ${response['status']} - $errorMsg');
        
        if (errorMsg.contains('Data anak tidak ditemukan') || 
            errorMsg.contains('tidak ditemukan')) {
          throw Exception('Data anak tidak ditemukan');
        }
        
        throw Exception(errorMsg);
      }
      
      if (response['status'] == 'success' || response['success'] == true) {
        if (response['data'] == null) {
          // Data is null but success is true - return empty list
          print('API mengembalikan success tanpa data untuk anak $anakId');
          return [];
        }
        
        final vitaminList = response['data'] as List;
        print('Berhasil mendapatkan ${vitaminList.length} data vitamin untuk anak $anakId dari API');
        return vitaminList;
      } 
      
      // Fallback for unexpected response structure
      print('API mengembalikan respons tidak terduga: $response');
      return [];
      
    } catch (e) {
      print('Error saat mengambil data vitamin untuk anak: $e');
      if (e.toString().contains('Data anak tidak ditemukan')) {
        throw Exception('Data anak tidak ditemukan');
      }
      throw Exception('Gagal mendapatkan data vitamin untuk anak: $e');
    }
  }

  /// Mendapatkan jadwal vitamin untuk anak berdasarkan usia
  Future<Map<String, dynamic>> getJadwalForAnak(int anakId) async {
    try {
      final response = await _apiService.get('vitamin/jadwal/anak/$anakId');
      
      if (response['status'] == 'success') {
        final result = {
          'data': response['data'] as List,
          'anak': response['anak'] as Map<String, dynamic>
        };
        
        print('Berhasil mendapatkan jadwal vitamin untuk anak $anakId (usia ${response['anak']['umur_hari']} hari)');
        return result;
      } else {
        print('API mengembalikan status bukan success: ${response['status']}');
        throw Exception(response['message'] ?? 'Gagal mendapatkan jadwal vitamin untuk anak');
      }
    } catch (e) {
      print('Error saat mengambil jadwal vitamin untuk anak: $e');
      return {
        'data': [],
        'anak': {}
      }; // Return empty data on error
    }
  }

  /// Mendapatkan jadwal vitamin dengan status implementasi
  Future<List<dynamic>> getJadwalWithStatus({DateTime? startDate, DateTime? endDate}) async {
    try {
      String endpoint = 'vitamin/jadwal/status';
      
      // Tambahkan filter date range jika ada
      if (startDate != null && endDate != null) {
        final formatter = DateFormat('yyyy-MM-dd');
        endpoint += '?start_date=${formatter.format(startDate)}&end_date=${formatter.format(endDate)}';
      }
      
      final response = await _apiService.get(endpoint);
      
      if (response['status'] == 'success') {
        final jadwalList = response['data'] as List;
        print('Berhasil mendapatkan ${jadwalList.length} jadwal vitamin dengan status dari API');
        return jadwalList;
      } else {
        print('API mengembalikan status bukan success: ${response['status']}');
        throw Exception(response['message'] ?? 'Gagal mendapatkan jadwal vitamin dengan status');
      }
    } catch (e) {
      print('Error saat mengambil jadwal vitamin dengan status: $e');
      return []; // Return empty list on error
    }
  }

  /// Update status vitamin
  Future<Map<String, dynamic>> updateVitaminStatus(int id, String status, {DateTime? tanggal}) async {
    try {
      Map<String, dynamic> data = {'status': status};
      
      // Tambahkan tanggal jika ada
      if (tanggal != null) {
        final formatter = DateFormat('yyyy-MM-dd');
        data['tanggal'] = formatter.format(tanggal);
      }
      
      final response = await _apiService.post('vitamin/$id', data);
      
      if (response['status'] == 'success') {
        print('Berhasil memperbarui status vitamin dengan ID $id menjadi $status');
        return response['data'];
      } else {
        print('API mengembalikan status bukan success: ${response['status']}');
        throw Exception(response['message'] ?? 'Gagal memperbarui status vitamin');
      }
    } catch (e) {
      print('Error saat memperbarui status vitamin: $e');
      throw Exception('Gagal memperbarui status vitamin: $e');
    }
  }

  /// Mendaftarkan anak untuk jadwal vitamin
  Future<Map<String, dynamic>> registerForJadwal(int jadwalId, int anakId) async {
    try {
      Map<String, dynamic> data = {
        'jadwal_vitamin_id': jadwalId,
        'anak_id': anakId
      };
      
      final response = await _apiService.post('vitamin/create-from-jadwal', data);
      
      if (response['status'] == 'success') {
        print('Berhasil mendaftarkan anak untuk jadwal vitamin');
        return response['data'];
      } else {
        print('API mengembalikan status bukan success: ${response['status']}');
        throw Exception(response['message'] ?? 'Gagal mendaftarkan anak untuk jadwal vitamin');
      }
    } catch (e) {
      print('Error saat mendaftarkan anak untuk jadwal vitamin: $e');
      throw Exception('Gagal mendaftarkan anak untuk jadwal vitamin: $e');
    }
  }

  /// Mendapatkan anak yang eligible untuk jadwal vitamin tertentu
  Future<List<dynamic>> getEligibleChildren(int jadwalId) async {
    try {
      final response = await _apiService.get('vitamin/jadwal/$jadwalId/eligible-children');
      
      if (response['success'] == true) {
        final children = response['data'] as List;
        print('Berhasil mendapatkan ${children.length} anak yang eligible untuk jadwal vitamin $jadwalId');
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
      final response = await _apiService.get('vitamin/jadwal/$jadwalId/status');
      
      if (response['success'] == true) {
        final data = response['data'][0] as Map<String, dynamic>;
        print('Berhasil mendapatkan status implementasi jadwal vitamin $jadwalId');
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
      final response = await _apiService.post('vitamin/jadwal/$jadwalId/complete', {});
      
      if (response['success'] == true) {
        print('Berhasil menandai jadwal vitamin $jadwalId sebagai selesai');
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

  /// Konversi status vitamin dari API ke tampilan di UI
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

  /// Mendapatkan warna untuk status vitamin
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

  /// Mendapatkan icon untuk status vitamin
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
