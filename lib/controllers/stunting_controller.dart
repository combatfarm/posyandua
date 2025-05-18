import 'package:flutter/material.dart';
import '../models/stunting_model.dart';

class StuntingController {
  List<StuntingData> _stuntingData = [];

  // Getter
  List<StuntingData> get stuntingData => _stuntingData;

  // Constructor
  StuntingController() {
    _initializeData();
  }

  // Inisialisasi data
  void _initializeData() {
    // Initialize with empty list for now
    _stuntingData = [];
  }

  // Add new stunting data
  void addStuntingData(StuntingData data) {
    _stuntingData.add(data);
  }

  // Get latest stunting data
  StuntingData? getLatestStuntingData() {
    if (_stuntingData.isEmpty) return null;
    return _stuntingData.reduce((a, b) => 
      a.tanggalPemeriksaan.isAfter(b.tanggalPemeriksaan) ? a : b
    );
  }

  // Determine Z-score status
  String getZScoreStatus(double tinggi, int usia, String gender) {
    // This is a simplified dummy implementation
    // In a real app, you would use WHO growth charts
    if (tinggi < 65 && usia > 12) {
      return 'Stunting';
    } else if (tinggi < 70 && usia > 24) {
      return 'Risiko Stunting';
    } else {
      return 'Normal';
    }
  }

  // Get status details
  Map<String, dynamic> getStatusDetails(String status) {
    switch (status) {
      case 'Stunting':
        return {
          'color': Colors.red,
          'icon': Icons.warning,
          'message': 'Anak terdeteksi stunting. Segera konsultasi dengan dokter atau petugas kesehatan.',
        };
      case 'Risiko Stunting':
        return {
          'color': Colors.orange,
          'icon': Icons.warning_amber,
          'message': 'Anak berisiko stunting. Tingkatkan asupan gizi dan lakukan pemeriksaan rutin.',
        };
      default:
        return {
          'color': Colors.green,
          'icon': Icons.check_circle,
          'message': 'Anak memiliki tinggi badan normal sesuai usia. Pertahankan asupan gizi seimbang.',
        };
    }
  }
} 