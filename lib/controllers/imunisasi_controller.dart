import 'package:flutter/material.dart';
import '../models/imunisasi_model.dart';
import '../services/imunisasi_service.dart';
import '../services/anak_service.dart';

class ImunisasiController {
  final ImunisasiService _imunisasiService = ImunisasiService();
  List<Imunisasi> _imunisasiList = [];
  final Map<String, bool> _jenisExpanded = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Imunisasi> get imunisasiList => _imunisasiList;
  Map<String, bool> get jenisExpanded => _jenisExpanded;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Constructor
  ImunisasiController() {
    // Tidak lagi perlu memanggil _initializeData() karena
    // data akan diambil dari API saat loadImunisasiForAnak dipanggil
  }

  // Load data imunisasi untuk anak tertentu dari API
  Future<void> loadImunisasiForAnak(int anakId) async {
    _isLoading = true;
    _error = null;
    
    try {
      // Kosongkan list terlebih dahulu untuk memastikan tidak ada data lama
      _imunisasiList = [];
      _jenisExpanded.clear();
      
      final imunisasiData = await _imunisasiService.getImunisasiByAnakId(anakId);
      
      if (imunisasiData.isNotEmpty) {
        _imunisasiList = imunisasiData.map((data) {
          // Convert API data to Imunisasi model using the fromApi factory
          return Imunisasi.fromApi(
            data,
            defaultColor: _getColorForImunisasi(data['jenis_imunisasi']['nama'] ?? ''),
          );
        }).toList();
        
        // Reset jenisExpanded
        _jenisExpanded.clear();
        for (var imunisasi in _imunisasiList) {
          _jenisExpanded[imunisasi.jenis] = false;
        }
      }
      
      _isLoading = false;
    } catch (e) {
      print('Error loading imunisasi: $e');
      _error = 'Gagal memuat data imunisasi: $e';
      _isLoading = false;
      
      // Re-throw the exception so it can be caught by the calling method
      throw e;
    }
  }
  
  // Tambahkan method untuk mendapatkan data anak berdasarkan ID
  Future<Map<String, dynamic>> getAnakById(int anakId) async {
    try {
      // Gunakan AnakService jika tersedia
      // final anakService = AnakService();
      // return await anakService.getAnakById(anakId);
      
      // Fallback: Gunakan ImunisasiService untuk mendapatkan data anak
      return await _imunisasiService.getAnakData(anakId);
    } catch (e) {
      print('Error getting anak data: $e');
      throw Exception('Gagal mendapatkan data anak: $e');
    }
  }

  // Check if all immunizations for a child are complete
  Future<bool> isImunisasiComplete(int anakId) async {
    try {
      await loadImunisasiForAnak(anakId);
      
      // If there are no immunizations or the list is empty, return false
      if (_imunisasiList.isEmpty) {
        return false;
      }
      
      // Check if all immunizations have 'Sudah' status
      final uncompletedImunisasi = _imunisasiList.where(
        (imunisasi) => imunisasi.status != 'Sudah'
      ).toList();
      
      // If there are no uncompleted immunizations, then all are complete
      return uncompletedImunisasi.isEmpty;
    } catch (e) {
      print('Error checking complete immunization status: $e');
      return false;
    }
  }

  // Load jadwal imunisasi berdasarkan usia anak
  Future<void> loadJadwalImunisasiForAnak(int anakId) async {
    _isLoading = true;
    _error = null;
    
    try {
      final result = await _imunisasiService.getJadwalForAnak(anakId);
      final jadwalList = result['data'] as List;
      
      if (jadwalList.isNotEmpty) {
        _imunisasiList = jadwalList.map((data) {
          final jadwal = data['jadwal'];
          final jenisImunisasi = data['jenis_imunisasi'];
          final isImplemented = data['is_implemented'] ?? false;
          
          // Determine status based on implementation
          String status = isImplemented ? 'Sudah' : 'Jadwal';
          
          // If there's an existing imunisasi record, use its status
          if (data['imunisasi'] != null) {
            status = _imunisasiService.getStatusDisplay(data['imunisasi']['status']);
          }

          // Prepare data for Imunisasi.fromApi
          Map<String, dynamic> imunisasiData = {
            'id': data['imunisasi']?['id'],
            'jenis_imunisasi': jenisImunisasi,
            'tanggal': jadwal['tanggal'],
            'status': status,
            'lokasi': jadwal['lokasi'] ?? 'Posyandu',
            'anak_id': anakId,
            'jenis_id': jenisImunisasi['id'],
            'jadwal_imunisasi_id': jadwal['id'],
          };
          
          return Imunisasi.fromApi(
            imunisasiData,
            defaultColor: _getColorForImunisasi(jenisImunisasi['nama'] ?? ''),
          );
        }).toList();
        
        // Reset jenisExpanded
        _jenisExpanded.clear();
        for (var imunisasi in _imunisasiList) {
          _jenisExpanded[imunisasi.jenis] = false;
        }
      }
      
      _isLoading = false;
    } catch (e) {
      print('Error loading jadwal imunisasi: $e');
      _error = 'Gagal memuat jadwal imunisasi: $e';
      _isLoading = false;
    }
  }

  // Update status imunisasi
  Future<void> updateImunisasiStatus(int imunisasiId, String newStatus) async {
    try {
      await _imunisasiService.updateImunisasiStatus(imunisasiId, newStatus);
      
      // Refresh data setelah update
      // Note: anakId bisa disimpan sebagai property class saat loadImunisasiForAnak dipanggil
    } catch (e) {
      _error = 'Gagal memperbarui status imunisasi: $e';
    }
  }

  // Mengubah status expanded untuk jenis tertentu
  void toggleJenisExpanded(String jenis) {
    _jenisExpanded[jenis] = !(_jenisExpanded[jenis] ?? false);
  }

  // Mendapatkan jumlah imunisasi berdasarkan status
  int getCountByStatus(String status) {
    if (status == 'Sudah') {
      // Count status that contain 'Sudah' or 'Selesai'
      return _imunisasiList.where((v) => 
        v.status == 'Sudah' || 
        v.status.toLowerCase().contains('sudah') ||
        v.status.toLowerCase().contains('selesai')
      ).length;
    }
    return _imunisasiList.where((v) => v.status == status).length;
  }

  // Mendapatkan imunisasi berdasarkan jenis
  List<Imunisasi> getImunisasiByJenis(String jenis) {
    return _imunisasiList.where((v) => v.jenis == jenis).toList();
  }

  // Helper methods
  Color _getColorForImunisasi(String jenis) {
    // Map some common imunisasi types to colors
    switch (jenis.toLowerCase()) {
      case 'hb-0':
      case 'hepatitis b':
        return Colors.blue;
      case 'bcg':
        return Colors.purple;
      case 'dpt':
      case 'dpt-hb-hib':
        return Colors.green;
      case 'polio':
        return Colors.red;
      case 'campak':
      case 'mr':
        return Colors.orange;
      default:
        // Generate a color based on the hash of the name
        return Colors.primaries[jenis.hashCode % Colors.primaries.length];
    }
  }
} 