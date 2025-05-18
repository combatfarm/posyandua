class JadwalModel {
  final int id;
  final int? anakId;
  final String nama;
  final String jenis;
  final DateTime tanggal;
  final String? waktu;
  final String? status;
  final String? keterangan;
  final int? minUmurHari;
  final int? maxUmurHari;
  final int? minUmurBulan;
  final int? maxUmurBulan;
  final bool? isImplemented;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? judul;

  JadwalModel({
    required this.id,
    this.anakId,
    required this.nama,
    required this.jenis,
    required this.tanggal,
    this.waktu,
    this.status,
    this.keterangan,
    this.minUmurHari,
    this.maxUmurHari,
    this.minUmurBulan,
    this.maxUmurBulan,
    this.isImplemented,
    required this.createdAt,
    required this.updatedAt,
    this.judul,
  });

  factory JadwalModel.fromJson(Map<String, dynamic> json) {
    // Debug print untuk melihat data yang diterima
    print('Parsing JadwalModel from JSON: $json');

    try {
      // Parse tanggal dengan error handling
      DateTime parseDate(String? dateStr) {
        if (dateStr == null) return DateTime.now();
        try {
          return DateTime.parse(dateStr);
        } catch (e) {
          print('Error parsing date $dateStr: $e');
          return DateTime.now();
        }
      }

      // Parse boolean dengan error handling
      bool? parseBool(dynamic value) {
        if (value == null) return null;
        if (value is bool) return value;
        if (value is int) return value == 1;
        if (value is String) {
          return value.toLowerCase() == 'true' || value == '1';
        }
        return null;
      }

      // Parse integer dengan error handling
      int? parseInt(dynamic value) {
        if (value == null) return null;
        if (value is int) return value;
        if (value is String) {
          try {
            return int.parse(value);
          } catch (e) {
            print('Error parsing int $value: $e');
            return null;
          }
        }
        return null;
      }

      // Gunakan judul jika nama kosong
      String getNama() {
        if (json['nama']?.toString().isNotEmpty == true) {
          return json['nama'].toString();
        }
        if (json['judul']?.toString().isNotEmpty == true) {
          return json['judul'].toString();
        }
        return 'Jadwal Baru'; // Default value jika nama dan judul kosong
      }

      final model = JadwalModel(
        id: json['id'] ?? 0,
        anakId: parseInt(json['anak_id']),
        nama: getNama(),
        jenis: json['jenis']?.toString() ?? '-',
        tanggal: parseDate(json['tanggal']),
        waktu: json['waktu']?.toString() ?? json['jam']?.toString(),
        status: json['status']?.toString(),
        keterangan: json['keterangan']?.toString(),
        minUmurHari: parseInt(json['min_umur_hari']),
        maxUmurHari: parseInt(json['max_umur_hari']),
        minUmurBulan: parseInt(json['min_umur_bulan']),
        maxUmurBulan: parseInt(json['max_umur_bulan']),
        isImplemented: parseBool(json['is_implemented']),
        createdAt: parseDate(json['created_at']),
        updatedAt: parseDate(json['updated_at']),
        judul: json['judul']?.toString(),
      );

      print('Successfully created JadwalModel: ${model.toJson()}');
      return model;
    } catch (e, stackTrace) {
      print('Error creating JadwalModel: $e');
      print('Stack trace: $stackTrace');
      print('Problematic JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'anak_id': anakId,
      'nama': nama,
      'jenis': jenis,
      'tanggal': tanggal.toIso8601String(),
      'waktu': waktu,
      'status': status,
      'keterangan': keterangan,
      'min_umur_hari': minUmurHari,
      'max_umur_hari': maxUmurHari,
      'min_umur_bulan': minUmurBulan,
      'max_umur_bulan': maxUmurBulan,
      'is_implemented': isImplemented,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'judul': judul,
    };
  }
}
