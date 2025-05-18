class StuntingData {
  final String namaPasien;
  final int usia;
  final double tinggiBadan;
  final double beratBadan;
  final double lingkarKepala;
  final String catatanTambahan;
  final DateTime tanggalPemeriksaan;
  final String status;
  final String gender;

  StuntingData({
    required this.namaPasien,
    required this.usia,
    required this.tinggiBadan,
    required this.beratBadan,
    required this.lingkarKepala,
    required this.catatanTambahan,
    required this.tanggalPemeriksaan,
    required this.status,
    required this.gender,
  });

  factory StuntingData.fromMap(Map<String, dynamic> map) {
    return StuntingData(
      namaPasien: map['namaPasien'] as String,
      usia: map['usia'] as int,
      tinggiBadan: map['tinggiBadan'] as double,
      beratBadan: map['beratBadan'] as double,
      lingkarKepala: map['lingkarKepala'] as double,
      catatanTambahan: map['catatanTambahan'] as String,
      tanggalPemeriksaan: map['tanggalPemeriksaan'] as DateTime,
      status: map['status'] as String,
      gender: map['gender'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'namaPasien': namaPasien,
      'usia': usia,
      'tinggiBadan': tinggiBadan,
      'beratBadan': beratBadan,
      'lingkarKepala': lingkarKepala,
      'catatanTambahan': catatanTambahan,
      'tanggalPemeriksaan': tanggalPemeriksaan,
      'status': status,
      'gender': gender,
    };
  }
}
