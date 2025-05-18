import 'package:flutter/material.dart';

class Vitamin {
  final int id;
  final String jenis;
  final String usia;
  final String tanggal;
  final String status;
  final String deskripsi;
  final String lokasi;
  final String manfaat;
  final Color color;

  Vitamin({
    required this.id,
    required this.jenis,
    required this.usia,
    required this.tanggal,
    required this.status,
    required this.deskripsi,
    required this.lokasi,
    required this.manfaat,
    required this.color,
  });

  // Create a Vitamin object from JSON data
  factory Vitamin.fromJson(Map<String, dynamic> json) {
    // Parse color - assume a default if not specified
    Color itemColor = Colors.blue;
    if (json['jenis_vitamin'] != null) {
      String jenisLower = json['jenis_vitamin']['nama']?.toString().toLowerCase() ?? '';
      
      if (jenisLower.contains('biru')) {
        itemColor = Colors.blue;
      } else if (jenisLower.contains('merah')) {
        itemColor = Colors.red;
      } else if (jenisLower.contains('kuning')) {
        itemColor = Colors.amber;
      }
    }

    // Handle different field names from API
    return Vitamin(
      id: json['id'] ?? 0,
      jenis: json['jenis_vitamin']?['nama'] ?? json['jenis'] ?? 'Vitamin A',
      usia: _formatUsia(json),
      tanggal: json['tanggal'] ?? '2024-01-01',
      status: json['status'] ?? 'Belum',
      deskripsi: json['jenis_vitamin']?['deskripsi'] ?? 'Pemberian vitamin A',
      lokasi: json['lokasi'] ?? 'Posyandu Mahoni 54',
      manfaat: json['jenis_vitamin']?['manfaat'] ?? 'Membantu pertumbuhan dan daya tahan tubuh.',
      color: itemColor,
    );
  }

  // Helper to format usia from API data
  static String _formatUsia(Map<String, dynamic> json) {
    // Try to get from min_umur_bulan if available
    if (json['jenis_vitamin'] != null && 
        json['jenis_vitamin']['min_umur_bulan'] != null) {
      return '${json['jenis_vitamin']['min_umur_bulan']} bulan';
    }
    
    // Use usia field if provided
    if (json['usia'] != null) {
      return json['usia'];
    }
    
    // Calculate from anak data if available
    if (json['anak'] != null && json['anak']['umur_bulan'] != null) {
      return '${json['anak']['umur_bulan']} bulan';
    }

    return '0 bulan'; // Default
  }

  // Convert Map to Vitamin object
  factory Vitamin.fromMap(Map<String, dynamic> map) {
    return Vitamin(
      id: map['id'] as int,
      jenis: map['jenis'] as String,
      usia: map['usia'] as String,
      tanggal: map['tanggal'] as String,
      status: map['status'] as String,
      deskripsi: map['deskripsi'] as String,
      lokasi: map['lokasi'] as String,
      manfaat: map['manfaat'] as String,
      color: map['color'] as Color,
    );
  }

  // Convert Vitamin object to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jenis': jenis,
      'usia': usia,
      'tanggal': tanggal,
      'status': status,
      'deskripsi': deskripsi,
      'lokasi': lokasi,
      'manfaat': manfaat,
      'color': color,
    };
  }
}
