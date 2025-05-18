import 'package:flutter/material.dart';

class Imunisasi {
  final int? id;
  final String jenis;
  final String usia;
  final String tanggal;
  final String status;
  final String deskripsi;
  final String lokasi;
  final String manfaat;
  final Color color;
  final int? anakId;
  final int? jenisId;
  final int? jadwalId;
  final int? minUmurHari;
  final int? maxUmurHari;

  Imunisasi({
    this.id,
    required this.jenis,
    required this.usia,
    required this.tanggal,
    required this.status,
    required this.deskripsi,
    required this.lokasi,
    required this.manfaat,
    required this.color,
    this.anakId,
    this.jenisId,
    this.jadwalId,
    this.minUmurHari,
    this.maxUmurHari,
  });

  // Convert Map to Imunisasi object
  factory Imunisasi.fromMap(Map<String, dynamic> map) {
    return Imunisasi(
      id: map['id'],
      jenis: map['jenis'] as String,
      usia: map['usia'] as String,
      tanggal: map['tanggal'] as String,
      status: map['status'] as String,
      deskripsi: map['deskripsi'] as String,
      lokasi: map['lokasi'] as String,
      manfaat: map['manfaat'] as String,
      color: map['color'] as Color,
      anakId: map['anak_id'],
      jenisId: map['jenis_id'],
      jadwalId: map['jadwal_imunisasi_id'],
      minUmurHari: map['min_umur_hari'],
      maxUmurHari: map['max_umur_hari'],
    );
  }

  // Convert API response to Imunisasi object
  factory Imunisasi.fromApi(Map<String, dynamic> map, {Color defaultColor = Colors.blue}) {
    // Extract jenis_imunisasi if available
    Map<String, dynamic> jenisImunisasi = {};
    if (map['jenis_imunisasi'] != null) {
      jenisImunisasi = map['jenis_imunisasi'] as Map<String, dynamic>;
    }

    return Imunisasi(
      id: map['id'],
      jenis: jenisImunisasi['nama'] ?? map['jenis'] ?? 'Unknown',
      usia: map['usia'] ?? '0 bulan',
      tanggal: map['tanggal'] ?? 'N/A',
      status: map['status'] ?? 'Belum',
      deskripsi: jenisImunisasi['deskripsi'] ?? map['deskripsi'] ?? '',
      lokasi: map['lokasi'] ?? 'Posyandu',
      manfaat: jenisImunisasi['manfaat'] ?? map['manfaat'] ?? '',
      color: defaultColor,
      anakId: map['anak_id'],
      jenisId: map['jenis_id'] ?? jenisImunisasi['id'],
      jadwalId: map['jadwal_imunisasi_id'],
      minUmurHari: jenisImunisasi['min_umur_hari'] ?? map['min_umur_hari'],
      maxUmurHari: jenisImunisasi['max_umur_hari'] ?? map['max_umur_hari'],
    );
  }

  // Convert Imunisasi object to Map
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
      'anak_id': anakId,
      'jenis_id': jenisId,
      'jadwal_imunisasi_id': jadwalId,
      'min_umur_hari': minUmurHari,
      'max_umur_hari': maxUmurHari,
    };
  }

  // Convert to API format for submission
  Map<String, dynamic> toApiMap() {
    return {
      'jenis_id': jenisId,
      'status': status,
      'tanggal': tanggal,
    };
  }
}
