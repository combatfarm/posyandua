import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.4:8000/api';
  static const Duration _defaultTimeout = Duration(seconds: 3);
  static const bool _enableLogging = true;

  // Cache untuk mengurangi panggilan berulang
  static final Map<String, dynamic> _responseCache = {};
  static const bool _enableCacheForPerkembangan = false;

  String? _token;
  bool _isLoadingToken = false;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal() {
    // Load token saat instance dibuat
    loadToken();
  }

  /// Generic request method that handles all HTTP methods
  Future<Map<String, dynamic>> request({
    required String method,
    required String endpoint,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Pastikan token sudah dimuat sebelum melakukan request
      if (_token == null && !_isLoadingToken) {
        await loadToken();
      }

      // Jika masih tidak ada token dan bukan endpoint auth, throw error
      if (_token == null && !endpoint.startsWith('auth/')) {
        throw Exception('No authentication token available. Please login first.');
      }

      final url = Uri.parse('$baseUrl/$endpoint');
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      // Add authorization header if token exists
      if (_token != null) {
        headers['Authorization'] = 'Bearer $_token';
      }

      // Log request if enabled
      if (_enableLogging) {
        print('$method Request to: $url');
        print('Headers: ${headers.toString()}');
        if (data != null) print('Body: ${json.encode(data)}');
    } 

      http.Response response;
      switch (method.toLowerCase()) {
        case 'get':
          // Check cache for GET requests
          if (_responseCache.containsKey(endpoint) && 
              !endpoint.startsWith('perkembangan') && 
              _enableCacheForPerkembangan) {
      if (_enableLogging) print('Using cached response for $endpoint');
      return _responseCache[endpoint];
    }

          response = await http.get(url, headers: headers)
              .timeout(_defaultTimeout);
          break;
          
        case 'post':
          response = await http.post(
            url,
            headers: headers,
            body: data != null ? json.encode(data) : null,
          ).timeout(_defaultTimeout);
          break;
          
        case 'put':
          response = await http.put(
            url,
            headers: headers,
            body: data != null ? json.encode(data) : null,
          ).timeout(_defaultTimeout);
          break;
          
        case 'delete':
          response = await http.delete(url, headers: headers)
              .timeout(_defaultTimeout);
          break;
          
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      if (_enableLogging) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body.length > 300 ? response.body.substring(0, 300) + '...' : response.body}');
      }

      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        // Clear token and cache
        await clearToken();
        clearAuthCache();
        throw Exception('Session expired. Please login again.');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(response.body);
        
        // Cache GET responses (except for perkembangan if disabled)
        if (method.toLowerCase() == 'get' && 
            !endpoint.startsWith('perkembangan') && 
            _enableCacheForPerkembangan) {
          _responseCache[endpoint] = responseData;
        }
        
        // Invalidate cache for write operations
        if (method.toLowerCase() != 'get') {
          _invalidateRelatedCache(endpoint);
        }
        
        return responseData;
      } else {
        throw Exception('HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (_enableLogging) {
        print('API Error: $e');
        if (e.toString().contains('TimeoutException')) {
          print('!!! KONEKSI KE SERVER API TIMEOUT !!!');
          print('!!! Pastikan server API berjalan di $baseUrl !!!');
        } else if (e.toString().contains('SocketException')) {
          print('!!! SERVER API TIDAK DAPAT DIJANGKAU !!!');
          print('!!! Pastikan server API berjalan di $baseUrl !!!');
        }
      }
      throw Exception('API Error: $e');
    }
  }

  // Convenience methods that use the request method
  Future<Map<String, dynamic>> get(String endpoint) async {
    return request(method: 'get', endpoint: endpoint);
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    return request(method: 'post', endpoint: endpoint, data: data);
  }

  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    return request(method: 'put', endpoint: endpoint, data: data);
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    return request(method: 'delete', endpoint: endpoint);
  }

  // Token management
  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    if (_enableLogging) print('Token saved successfully');
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (_enableLogging) print('Token cleared');
  }

  Future<void> loadToken() async {
    if (_isLoadingToken) return;
    
    try {
      _isLoadingToken = true;
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      if (_enableLogging) {
        print(_token != null ? 'Token loaded successfully' : 'No token found');
      }
    } catch (e) {
      print('Error loading token: $e');
      _token = null;
    } finally {
      _isLoadingToken = false;
    }
  }
  
  // Cache management
  void _invalidateRelatedCache(String endpoint) {
    if (endpoint.startsWith('anak')) {
      _responseCache.removeWhere((key, _) => key.startsWith('anak'));
    } else if (endpoint.startsWith('perkembangan')) {
      _responseCache.removeWhere((key, _) => key.startsWith('perkembangan'));
    } else if (endpoint.startsWith('auth') || endpoint.startsWith('profile')) {
      _responseCache.removeWhere((key, _) => 
        key.startsWith('auth') || 
        key.startsWith('profile') ||
        key.startsWith('user')
      );
    }
  }

  void clearCache() {
    _responseCache.clear();
    if (_enableLogging) print('All API cache cleared');
  }
  
  void clearAuthCache() {
    _responseCache.removeWhere((key, _) => 
      key.startsWith('auth') || 
      key.startsWith('profile') ||
      key.startsWith('user')
    );
    if (_enableLogging) print('Auth-related cache cleared');
  }

  void clearChildCache() {
    _responseCache.removeWhere((key, _) => 
      key.startsWith('anak') || 
      key.contains('orangtua') || 
      key.contains('pengguna')
    );
    if (_enableLogging) print('Child-related cache cleared');
  }

  /// Memeriksa apakah server API dapat dijangkau
  Future<bool> isServerReachable() async {
    try {
      if (_enableLogging) {
        print('Memeriksa koneksi ke server API: $baseUrl');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/ping'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 5));
      
      if (_enableLogging) {
        print('Status koneksi server: ${response.statusCode}');
      }
      
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      if (_enableLogging) {
        print('Gagal terhubung ke server API: $e');
        if (e.toString().contains('TimeoutException')) {
          print('!!! KONEKSI KE SERVER API TIMEOUT !!!');
        } else if (e.toString().contains('SocketException')) {
          print('!!! SERVER API TIDAK DAPAT DIJANGKAU !!!');
        }
      }
      return false;
    }
  }
}
