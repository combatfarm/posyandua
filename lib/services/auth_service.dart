import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'api_service.dart';
import 'dart:math';

class AuthService {
  // Gunakan ApiService untuk request
  final ApiService _apiService = ApiService();
  
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  
  factory AuthService() {
    return _instance;
  }
  
  AuthService._internal();

  // Fungsi untuk login
  Future<Map<String, dynamic>> login({
    required String nik,
    required String password,
  }) async {
    try {
      print('Memulai proses login...');
      
      // Login tidak menggunakan token, jadi kita gunakan http langsung
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nik': nik,
          'password': password,
        }),
      );
      
      final data = jsonDecode(response.body);
      print('Response login: $data');
      
      if (response.statusCode == 200 && data['status'] == 'success') {
        print('Login berhasil');
        final prefs = await SharedPreferences.getInstance();
        
        // Store user data from API
        await prefs.setString('token', data['token'] ?? 'dummy_token_${DateTime.now().millisecondsSinceEpoch}');
        await prefs.setString('nik', data['pengguna']['nik']);
        await prefs.setString('nama_ibu', data['pengguna']['nama'] ?? '');
        
        // Simpan user_id sebagai integer untuk digunakan di fitur lain
        int userId = data['pengguna']['id'];
        await prefs.setInt('user_id', userId);
        print('User ID yang disimpan: $userId');
        
        // Simpan email dan no_telp jika tersedia
        if (data['pengguna']['email'] != null) {
          await prefs.setString('email', data['pengguna']['email']);
          print('Email saved: ${data['pengguna']['email']}');
        }
        
        if (data['pengguna']['no_telp'] != null) {
          await prefs.setString('no_telp', data['pengguna']['no_telp']);
          print('Phone saved: ${data['pengguna']['no_telp']}');
        } else if (data['pengguna']['telepon'] != null) {
          await prefs.setString('no_telp', data['pengguna']['telepon']);
          print('Phone saved (from telepon field): ${data['pengguna']['telepon']}');
        }
        
        if (data['pengguna']['alamat'] != null) {
          await prefs.setString('alamat', data['pengguna']['alamat']);
        }
        
        if (data['pengguna']['usia'] != null) {
          await prefs.setInt('usia', data['pengguna']['usia']);
        }
        
        // Save current child data if available
        if (data['pengguna']['anak'] != null && data['pengguna']['anak'].isNotEmpty) {
          final currentChild = data['pengguna']['anak'][0];
          await prefs.setString('nama_anak', currentChild['nama']);
          await prefs.setInt('usia_bulan_anak', currentChild['usia_bulan']);
          await prefs.setString('jenis_kelamin_anak', currentChild['jenis_kelamin']);
        }

        // Verifikasi data tersimpan
        final verifyUserId = prefs.getInt('user_id');
        final verifyEmail = prefs.getString('email');
        final verifyPhone = prefs.getString('no_telp');
        print('Verifikasi user_id tersimpan: $verifyUserId');
        print('Verifikasi email tersimpan: $verifyEmail');
        print('Verifikasi no_telp tersimpan: $verifyPhone');

        return {
          'success': true,
          'message': data['message'] ?? 'Login berhasil',
          'data': data['pengguna'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'NIK atau password salah',
        };
      }
    } catch (e) {
      print('Error during login: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
  // Fungsi untuk register
  Future<Map<String, dynamic>> register({
    required String nik,
    required String nama,
    required String alamat,
    required String noTelp,
    required String password,
    String? email,
  }) async {
    try {
      print('Memulai proses pendaftaran...');
      
      // Debug: Tampilkan URL yang digunakan
      print('API URL: ${ApiService.baseUrl}/register');
      
      // Register tidak menggunakan token, jadi kita gunakan http langsung
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nik': nik,
          'nama': nama,
          'alamat': alamat,
          'no_telp': noTelp,
          'password': password,
          'email': email,
          'role': 'parent', // Default role
        }),
      );
      
      // Debug: Tampilkan status code dan response body
      print('Status Code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body preview: ${response.body.substring(0, min(200, response.body.length))}...');
      
      // Cek apakah response berupa JSON atau HTML
      if (response.body.trim().startsWith('{') || response.body.trim().startsWith('[')) {
        // Response adalah JSON
        final data = jsonDecode(response.body);
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          print('Pendaftaran berhasil');
          
          // Simpan data pendaftaran ke SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          
          // Save registration data
          await prefs.setString('nik', nik);
          await prefs.setString('nama_ibu', nama);
          await prefs.setString('alamat', alamat);
          await prefs.setString('no_telp', noTelp);
          
          if (email != null && email.isNotEmpty) {
            await prefs.setString('email', email);
            print('Email saved from registration: $email');
          }
          
          // Jika ada ID pengguna di respons, simpan juga
          if (data['id'] != null) {
            await prefs.setInt('user_id', data['id']);
          } else if (data['user_id'] != null) {
            await prefs.setInt('user_id', data['user_id']);
          } else if (data['pengguna'] != null && data['pengguna']['id'] != null) {
            await prefs.setInt('user_id', data['pengguna']['id']);
          }
          
          print('Registration data saved to SharedPreferences:');
          print('NIK: $nik');
          print('Nama: $nama');
          print('No Telp: $noTelp');
          print('Email: $email');
          
          return {
            'success': true,
            'message': data['message'] ?? 'Pendaftaran berhasil',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Pendaftaran gagal',
            'errors': data['errors'],
            'statusCode': response.statusCode
          };
        }
      } else {
        // Response bukan JSON (kemungkinan HTML error page)
        return {
          'success': false,
          'message': 'Server mengembalikan format yang tidak valid (bukan JSON)',
          'statusCode': response.statusCode,
          'rawResponse': response.body.length > 100 
              ? '${response.body.substring(0, 100)}...' 
              : response.body
        };
      }
    } catch (e) {
      print('Error during registration: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
  // Fungsi untuk mendapatkan data user yang sedang login
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nik = prefs.getString('nik');
      final userId = prefs.getInt('user_id');
      
      if (nik == null) {
        return {
          'success': false,
          'message': 'User belum login',
        };
      }
      
      // Baca data lokal terlebih dahulu
      final localUserData = {
        'nik': nik,
        'id': userId,
        'nama': prefs.getString('nama_ibu') ?? 'User',
        'alamat': prefs.getString('alamat') ?? '',
        'usia': prefs.getInt('usia') ?? 0,
        'email': prefs.getString('email') ?? '',
        'no_telp': prefs.getString('no_telp') ?? '',
      };
      
      print('Local data from SharedPreferences:');
      print('Email: ${localUserData['email']}');
      print('Phone: ${localUserData['no_telp']}');
      
      try {
        // Gunakan endpoint yang benar (user, user/profile, atau me)
        print('Getting user data with token authentication');
        
        // Coba beberapa endpoint yang mungkin ada di Laravel API
        Map<String, dynamic> data = {};
        bool apiSuccess = false;
        
        try {
          data = await _apiService.get('user');
          apiSuccess = true;
        } catch (e) {
          print('Endpoint "user" failed: $e');
          try {
            data = await _apiService.get('me');
            apiSuccess = true;
          } catch (e) {
            print('Endpoint "me" failed: $e');
            try {
              data = await _apiService.get('user/profile');
              apiSuccess = true;
            } catch (e) {
              print('Endpoint "user/profile" failed: $e');
            }
          }
        }
        
        if (!apiSuccess || data.isEmpty) {
          print('No API endpoint worked, using local data');
          
          // Jika API tidak mengembalikan data, gunakan data lokal
          return {
            'success': true,
            'message': 'Menggunakan data lokal',
            'data': localUserData
          };
        }
        
        // Debug: Check response structure
        print('API response structure for getCurrentUser:');
        print('Keys: ${data.keys.toList()}');
        
        // Berdasarkan struktur response API
        Map<String, dynamic> userData = data;
        if (data['user'] != null) {
          userData = data['user'];
        } else if (data['pengguna'] != null) {
          userData = data['pengguna'];
        } else if (data['data'] != null) {
          userData = data['data'];
        }
        
        // Gabungkan data API dengan data lokal jika ada field yang kosong di API
        if (userData['email'] == null && localUserData['email'] != null && localUserData['email'] != '') {
          userData['email'] = localUserData['email'];
        }
        
        if ((userData['no_telp'] == null && userData['telepon'] == null) && 
            localUserData['no_telp'] != null && localUserData['no_telp'] != '') {
          userData['no_telp'] = localUserData['no_telp'];
        }
        
        return {
          'success': true,
          'data': userData,
        };
      } catch (e) {
        print('Error in getCurrentUser: $e');
        
        // Jika API error, gunakan data lokal
        return {
          'success': true,
          'message': 'Menggunakan data lokal karena API error: $e',
          'data': localUserData
        };
      }
    } catch (e) {
      print('Error getting current user: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Fungsi untuk cek status login
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      return token != null;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Fungsi logout
  Future<bool> logout() async {
    try {
      try {
        // Gunakan ApiService untuk logout
        await _apiService.post('logout', {});
        print('User logged out successfully from API');
      } catch (e) {
        print('API logout failed, but will clear local data: $e');
      }
      
      // Hanya hapus token autentikasi, bukan semua data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      return true;
    } catch (e) {
      print('Logout error: $e');
      // Tetap hapus token meskipun terjadi error
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
      } catch (clearError) {
        print('Error removing token: $clearError');
      }
      return true;
    }
  }
}
