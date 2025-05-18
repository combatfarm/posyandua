import 'package:posyandu/models/profile_model.dart';
import 'package:posyandu/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  final ApiService _apiService = ApiService();

  Future<ProfileModel> getProfile() async {
    try {
      final response = await _apiService.get('profile');
      return ProfileModel.fromJson(response);
    } catch (e) {
      print('Failed to load profile from API: $e');
      
      // Fallback to SharedPreferences data
      try {
        final prefs = await SharedPreferences.getInstance();
        final Map<String, dynamic> userData = {
          'id': prefs.getInt('user_id') ?? 0,
          'nik': prefs.getString('nik') ?? '',
          'nama': prefs.getString('nama_ibu') ?? 'User',
          'alamat': prefs.getString('alamat') ?? '',
          'usia': prefs.getInt('usia') ?? 0,
          'no_telp': prefs.getString('no_telp') ?? '',
          'email': prefs.getString('email') ?? '',
        };
        
        print('Using profile data from SharedPreferences: $userData');
        return ProfileModel.fromJson(userData);
      } catch (prefError) {
        print('Error accessing SharedPreferences: $prefError');
        throw Exception('Failed to load profile: $e');
      }
    }
  }

  Future<void> updateProfile(ProfileModel profile) async {
    try {
      // Get current user data first to ensure we have the correct ID
      final currentUser = await _apiService.get('user');
      if (currentUser['status'] != 'success' || currentUser['pengguna'] == null) {
        throw Exception('Failed to get current user data');
      }

      final userId = currentUser['pengguna']['id'];
      if (userId == null) {
        throw Exception('User ID not found in API response');
      }

      print('Updating profile for user ID: $userId');

      // Create update payload with correct field names
      final updateData = {
        'nama_ibu': profile.name,
        'email': profile.email,
        'no_telp': profile.phone,
        'alamat': profile.address,
        'nik': profile.nik,
      };

      // Call the API endpoint with ID from API response
      final response = await _apiService.put('user/$userId', updateData);
      
      // If successful, update local storage
      if (response['status'] == 'success' && response['pengguna'] != null) {
        final userData = response['pengguna'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('nama_ibu', userData['nama_ibu'] ?? '');
        await prefs.setString('email', userData['email'] ?? '');
        await prefs.setString('no_telp', userData['no_telp'] ?? '');
        await prefs.setString('alamat', userData['alamat'] ?? '');
        await prefs.setString('nik', userData['nik'] ?? '');
        await prefs.setInt('user_id', userId); // Update stored user ID
      } else {
        throw Exception(response['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      print('Error updating profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<List<dynamic>> getChildren({required int userId}) async {
    try {
      print('Fetching children for user ID: $userId');
      
      // Clear any cached data first
      _apiService.clearChildCache();
      
      // Try first endpoint
      try {
        final response = await _apiService.get('anak/orangtua/$userId');
        if (response.containsKey('data') && response['data'] is List) {
          final children = response['data'] as List;
          print('Found ${children.length} children via anak/orangtua endpoint');
          
          // Verifikasi bahwa jumlah anak masuk akal
          if (children.length > 0 && children.length <= 10) {
            return children;
          } else if (children.length > 10) {
            print('Unreasonably high number of children (${children.length}), limiting to first 3');
            return children.take(3).toList();
          }
          
          return children;
        }
      } catch (e) {
        print('First endpoint failed: $e');
      }
      
      // Try second endpoint
      try {
        final response = await _apiService.get('anak');
        if (response.containsKey('data') && response['data'] is List) {
          List<dynamic> allChildren = response['data'] as List;
          
          // Jika array kosong, langsung kembalikan array kosong
          if (allChildren.isEmpty) {
            print('API returned empty children array');
            return [];
          }
          
          List<dynamic> userChildren = allChildren.where((child) => 
            (child['id_orangtua'] == userId || child['id_ortu'] == userId)
          ).toList();
          
          print('Found ${userChildren.length} children via anak endpoint with filtering');
          
          // Verifikasi bahwa jumlah anak masuk akal
          if (userChildren.length > 0 && userChildren.length <= 10) {
            return userChildren;
          } else if (userChildren.length > 10) {
            print('Unreasonably high number of filtered children (${userChildren.length}), limiting to first 3');
            return userChildren.take(3).toList();
          }
          
          if (userChildren.isNotEmpty) {
            return userChildren;
          }
        }
      } catch (e) {
        print('Second endpoint failed: $e');
      }
      
      // Try third endpoint without filtering (for testing)
      try {
        final response = await _apiService.get('anak');
        if (response.containsKey('data') && response['data'] is List) {
          List<dynamic> allChildren = response['data'] as List;
          
          // Jika array kosong dari API, kembalikan array kosong
          if (allChildren.isEmpty) {
            print('API returned empty children array (unfiltered)');
            return [];
          }
          
          print('Found ${allChildren.length} total children via anak endpoint without filtering');
          
          // Verifikasi bahwa jumlah anak masuk akal
          if (allChildren.length > 10) {
            print('Unreasonably high number of all children (${allChildren.length}), limiting to first 3');
            return allChildren.take(3).toList();
          }
          
          // For testing, return all children regardless of parent
          return allChildren;
        }
      } catch (e) {
        print('Third endpoint failed: $e');
      }
      
      // Return last resort dummy data only if everything else fails
      print('All API endpoints failed - returning dummy data for testing');
      return [
        {
          'id': 999,
          'nama': 'Data Dummy - API Error',
          'jenis_kelamin': 'Laki-laki',
          'usia_bulan': 24
        }
      ];
    } catch (e) {
      print('Error in getChildren method: $e');
      
      // Return minimal dummy data
      return [
        {
          'id': 888,
          'nama': 'Error Data',
          'jenis_kelamin': 'Laki-laki',
          'usia_bulan': 1
        }
      ];
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.post('auth/logout', {});
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }
} 