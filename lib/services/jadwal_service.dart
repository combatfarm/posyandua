import 'package:posyandu/services/api_service.dart';
import 'package:posyandu/models/jadwal_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class JadwalService {
  final ApiService _apiService = ApiService();
  
  // Singleton pattern
  static final JadwalService _instance = JadwalService._internal();
  
  factory JadwalService() {
    return _instance;
  }
  
  JadwalService._internal();

  /// Mendapatkan semua jadwal (gabungan dari pemeriksaan, imunisasi, dan vitamin)
  Future<List<JadwalModel>> getAllJadwal() async {
    try {
      final response = await _apiService.get('jadwal');
      final data = response['data'];
      if (response['status'] == 'success' && data is List) {
        final jadwalList = data.map((json) => JadwalModel.fromJson(json)).toList();
        print('Berhasil mendapatkan ${jadwalList.length} jadwal dari API');
        return List<JadwalModel>.from(jadwalList);
      } else {
        print('API mengembalikan status bukan success atau data bukan List: ${response['status']}');
        throw Exception(response['message'] ?? 'Gagal mendapatkan data jadwal');
      }
    } catch (e) {
      print('Error saat mengambil data jadwal: $e');
      return [];
    }
  }

  /// Mendapatkan jadwal yang akan datang
  Future<List<JadwalModel>> getUpcomingJadwal() async {
    try {
      final response = await _apiService.get('jadwal/upcoming');
      final data = response['data'];
      if (response['status'] == 'success' && data is List) {
        final jadwalList = data.map((json) => JadwalModel.fromJson(json)).toList();
        print('Berhasil mendapatkan ${jadwalList.length} jadwal upcoming dari API');
        return List<JadwalModel>.from(jadwalList);
      } else {
        print('API mengembalikan status bukan success atau data bukan List: ${response['status']}');
        throw Exception(response['message'] ?? 'Gagal mendapatkan data jadwal upcoming');
      }
    } catch (e) {
      print('Error saat mengambil data jadwal upcoming: $e');
      return [];
    }
  }

  /// Mendapatkan jadwal yang akan datang untuk anak tertentu (filter usia)
  Future<List<JadwalModel>> getUpcomingJadwalForChild(int anakId) async {
    try {
      final response = await _apiService.get('jadwal/upcoming/anak/$anakId');
      final data = response['data'];
      if (response['status'] == 'success' && data is List) {
        final jadwalList = data.map((json) => JadwalModel.fromJson(json)).toList();
        print('Berhasil mendapatkan ${jadwalList.length} jadwal upcoming untuk anak $anakId dari API');
        return List<JadwalModel>.from(jadwalList);
      } else {
        print('API mengembalikan status bukan success atau data bukan List: ${response['status']}');
        throw Exception(response['message'] ?? 'Gagal mendapatkan data jadwal upcoming untuk anak');
      }
    } catch (e) {
      print('Error saat mengambil data jadwal upcoming untuk anak: $e');
      return [];
    }
  }

  /// Mendapatkan riwayat jadwal untuk anak tertentu
  Future<List<JadwalModel>> getRiwayatJadwalAnak(int anakId) async {
    try {
      final response = await _apiService.get('jadwal/riwayat/anak/$anakId');
      final data = response['data'];
      if (response['status'] == 'success' && data is List) {
        final jadwalList = data.map((json) => JadwalModel.fromJson(json)).toList();
        print('Berhasil mendapatkan ${jadwalList.length} riwayat jadwal untuk anak $anakId dari API');
        return List<JadwalModel>.from(jadwalList);
      } else {
        print('API mengembalikan status bukan success atau data bukan List: ${response['status']}');
        throw Exception(response['message'] ?? 'Gagal mendapatkan riwayat jadwal anak');
      }
    } catch (e) {
      print('Error saat mengambil riwayat jadwal anak: $e');
      return [];
    }
  }

  /// Menandai jadwal sebagai selesai
  Future<Map<String, dynamic>> markJadwalAsSelesai(int jadwalId, String jenisJadwal) async {
    try {
      String endpoint;
      Map<String, dynamic> requestData = {'is_implemented': true};
      
      switch (jenisJadwal.toLowerCase()) {
        case 'pemeriksaan rutin':
          endpoint = 'jadwal/pemeriksaan/$jadwalId/status';
          break;
        case 'imunisasi':
          endpoint = 'jadwal/imunisasi/$jadwalId/status';
          break;
        case 'vitamin':
          endpoint = 'jadwal/vitamin/$jadwalId/status';
          break;
        default:
          throw Exception('Jenis jadwal tidak dikenali: $jenisJadwal');
      }
      
      final response = await _apiService.post(endpoint, requestData);
      
      if (response['success'] == true) {
        print('Berhasil menandai jadwal $jadwalId ($jenisJadwal) sebagai selesai');
        return {
          'status': 'success',
          'message': response['message'] ?? 'Jadwal berhasil ditandai sebagai selesai'
        };
      } else {
        print('API mengembalikan status bukan success: ${response['success']}');
        throw Exception(response['message'] ?? 'Gagal menandai jadwal sebagai selesai');
      }
    } catch (e) {
      print('Error saat menandai jadwal sebagai selesai: $e');
      rethrow;
    }
  }

  /// Mendapatkan jadwal terdekat untuk anak tertentu
  Future<JadwalModel?> getNearestJadwalForChild(int anakId) async {
    try {
      final response = await _apiService.get('jadwal/nearest/$anakId');
      final data = response['data'];
      if (response['status'] == 'success' && data != null) {
        return JadwalModel.fromJson(data);
      } else {
        print('Tidak ada jadwal terdekat untuk anak $anakId.');
        return null;
      }
    } catch (e) {
      print('Error getNearestJadwalForChild: $e');
      return null;
    }
  }
}
