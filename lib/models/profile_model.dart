class ProfileModel {
  final dynamic id; // Support both int and string ID types
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? nik;
  final String? role;
  final int? age;
  final int childCount;
  final int scheduleCount;
  final String? photoUrl;
  final List<ChildModel> children;

  ProfileModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.nik,
    this.role,
    this.age,
    this.childCount = 0,
    this.scheduleCount = 0,
    this.photoUrl,
    required this.children,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    // Extract user data from nested structures if present
    Map<String, dynamic> userData = json;
    if (json['user'] != null) userData = json['user'];
    if (json['pengguna'] != null) userData = json['pengguna'];
    if (json['data'] != null) userData = json['data'];

    // Default empty list for children if none provided
    List<dynamic> childrenData = [];
    if (userData['children'] != null) childrenData = userData['children'];
    if (userData['anak'] != null) childrenData = userData['anak'];
    
    return ProfileModel(
      id: userData['id'] ?? 0,
      name: userData['name'] ?? userData['nama'] ?? 'User',
      email: userData['email'],
      phone: userData['phone'] ?? userData['no_telp'] ?? userData['telepon'] ?? '',
      address: userData['address'] ?? userData['alamat'] ?? '',
      nik: userData['nik'] ?? '',
      role: userData['role'] ?? 'parent',
      age: userData['age'] ?? userData['usia'] ?? 0,
      childCount: childrenData.length,
      scheduleCount: userData['scheduleCount'] ?? userData['jadwal_count'] ?? 0,
      photoUrl: userData['photoUrl'] ?? userData['photo'] ?? userData['foto'],
      children: childrenData.isNotEmpty
          ? childrenData.map<ChildModel>((child) => ChildModel.fromJson(child)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': name,
      'email': email,
      'no_telp': phone,
      'alamat': address,
      'nik': nik,
      'role': role,
      'usia': age,
      'anak': children.map((child) => child.toJson()).toList(),
    };
  }
}

class ChildModel {
  final dynamic id;
  final String name;
  final dynamic age; // Could be string or int depending on API
  final String gender;
  final String? height;
  final String? weight;
  final String? status;
  final String? photoUrl;
  final DateTime? birthDate;

  ChildModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.height = '',
    this.weight = '',
    this.status = 'normal',
    this.photoUrl,
    this.birthDate,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    // Handle birthdate in various formats
    DateTime? birthDateParsed;
    if (json['birthDate'] != null) {
      try {
        birthDateParsed = DateTime.parse(json['birthDate']);
      } catch(_) {}
    } else if (json['tanggal_lahir'] != null) {
      try {
        birthDateParsed = DateTime.parse(json['tanggal_lahir']);
      } catch(_) {}
    }
    
    return ChildModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['nama'] ?? 'Anak',
      age: json['age'] ?? json['usia'] ?? json['usia_bulan'] ?? '0',
      gender: json['gender'] ?? json['jenis_kelamin'] ?? 'Laki-laki',
      height: json['height'] ?? json['tinggi'] ?? '',
      weight: json['weight'] ?? json['berat'] ?? '',
      status: json['status'] ?? 'normal',
      photoUrl: json['photoUrl'] ?? json['foto'],
      birthDate: birthDateParsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': name,
      'usia': age,
      'jenis_kelamin': gender,
      'tinggi': height,
      'berat': weight,
      'status': status,
      'foto': photoUrl,
      'tanggal_lahir': birthDate?.toIso8601String(),
    };
  }
} 