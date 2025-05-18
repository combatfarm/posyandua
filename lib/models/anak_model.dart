class AnakModel {
  final int id;
  final String nama;
  final DateTime? tanggalLahir;
  final String? tempatLahir;
  final String? jenisKelamin;
  final String? anakKe;
  final int? beratBadan;
  final int? panjangBadan;
  final int? lingkarKepala;
  final String? golonganDarah;
  final String? bpjs;
  final String? ibuid;
  final String? kk;
  final String? foto;
  final int? keluargaId;

  AnakModel({
    required this.id,
    required this.nama,
    this.tanggalLahir,
    this.tempatLahir,
    this.jenisKelamin,
    this.anakKe,
    this.beratBadan,
    this.panjangBadan,
    this.lingkarKepala,
    this.golonganDarah,
    this.bpjs,
    this.ibuid,
    this.kk,
    this.foto,
    this.keluargaId,
  });
  
  // Factory method untuk membuat AnakModel dari JSON
  factory AnakModel.fromJson(Map<String, dynamic> json) {
    return AnakModel(
      id: json['id'],
      nama: json['nama'] ?? '',
      tanggalLahir: json['tanggal_lahir'] != null ? DateTime.parse(json['tanggal_lahir']) : null,
      tempatLahir: json['tempat_lahir'],
      jenisKelamin: json['jenis_kelamin'],
      anakKe: json['anak_ke'],
      beratBadan: json['berat_badan'],
      panjangBadan: json['panjang_badan'],
      lingkarKepala: json['lingkar_kepala'],
      golonganDarah: json['golongan_darah'],
      bpjs: json['bpjs'],
      ibuid: json['ibuid'],
      kk: json['kk'],
      foto: json['foto'],
      keluargaId: json['keluarga_id'],
    );
  }
  
  // Method untuk mengubah AnakModel menjadi JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'tanggal_lahir': tanggalLahir?.toIso8601String(),
      'tempat_lahir': tempatLahir,
      'jenis_kelamin': jenisKelamin,
      'anak_ke': anakKe,
      'berat_badan': beratBadan,
      'panjang_badan': panjangBadan,
      'lingkar_kepala': lingkarKepala,
      'golongan_darah': golonganDarah,
      'bpjs': bpjs,
      'ibuid': ibuid,
      'kk': kk,
      'foto': foto,
      'keluarga_id': keluargaId,
    };
  }
} 