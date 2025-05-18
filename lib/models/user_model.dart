class UserModel {
  final String nik;
  final String password;

  UserModel({
    required this.nik,
    required this.password,
  });

  // Convert JSON to UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      nik: json['nik'],
      password: json['password'],
    );
  }

  // Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'nik': nik,
      'password': password,
    };
  }
}
