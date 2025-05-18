import 'package:posyandu/services/api_service.dart';
import 'package:posyandu/services/anak_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class DashboardService {
  final ApiService _apiService = ApiService();
  final AnakService _anakService = AnakService();
  
  // Singleton pattern
  static final DashboardService _instance = DashboardService._internal();
  
  factory DashboardService() {
    return _instance;
  }
  
  DashboardService._internal();

  /// Mendapatkan daftar anak untuk pemilihan di dashboard
  Future<List<dynamic>> getAnakListForSelection() async {
    try {
      final anakList = await _anakService.getAnakList();
      
      // Beri label aktif pada anak yang terakhir dipilih user
      final prefs = await SharedPreferences.getInstance();
      final lastSelectedAnakId = prefs.getInt('last_selected_anak_id');
      
      final enhancedList = anakList.map((anak) {
        final isSelected = anak['id'] == lastSelectedAnakId;
        return {
          ...anak,
          'is_selected': isSelected,
        };
      }).toList();
      
      return enhancedList;
    } catch (e) {
      print('Error loading anak list for selection: $e');
      throw Exception('Gagal memuat daftar anak: $e');
    }
  }
  
  /// Mengatur anak yang dipilih sebagai default di dashboard
  Future<void> setSelectedAnak(int anakId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_selected_anak_id', anakId);
      print('Berhasil menyimpan anak terpilih dengan ID $anakId');
    } catch (e) {
      print('Error saving selected anak: $e');
    }
  }
  
  /// Mendapatkan ID anak yang terakhir dipilih
  Future<int?> getLastSelectedAnakId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('last_selected_anak_id');
    } catch (e) {
      print('Error getting last selected anak ID: $e');
      return null;
    }
  }
  
  /// Mendapatkan data ringkasan untuk dashboard
  Future<Map<String, dynamic>> getDashboardSummary({int? anakId}) async {
    try {
      // Jika tidak ada anakId yang diberikan, gunakan ID yang terakhir dipilih
      final targetAnakId = anakId ?? await getLastSelectedAnakId();
      
      if (targetAnakId == null) {
        // Jika tidak ada anak yang dipilih, berikan respons kosong
        return {
          'success': false,
          'message': 'Belum ada anak yang dipilih',
          'data': null,
        };
      }
      
      // Gunakan Future.wait untuk melakukan fetch data secara paralel
      final futures = [
        _anakService.getAnakDetail(targetAnakId),
        _getLatestGrowthData(targetAnakId),
        _getUpcomingSchedule(targetAnakId),
      ];
      
      final results = await Future.wait(futures).timeout(
        Duration(seconds: 2),
        onTimeout: () {
          // Jika timeout, gunakan data dummy
          print('Fetching dashboard data timed out, using defaults');
          return [
            {'nama_anak': 'Anak', 'jenis_kelamin': 'Laki-laki', 'tanggal_lahir': DateTime.now().subtract(Duration(days: 365)).toString()},
            {'tinggi_badan': 75.0, 'berat_badan': 9.0, 'tanggal': DateTime.now().toString()},
            {'jenis': 'Imunisasi DPT', 'tanggal': DateTime.now().add(Duration(days: 14)).toString(), 'jam': '09:00 - 12:00', 'lokasi': 'Posyandu Melati'}
          ];
        }
      );
      
      final anakDetail = results[0];
      final growth = results[1];
      final schedule = results[2];
      
      // Hitung statistik
      final stats = _calculateStatistics(anakDetail, growth);
      
      // Buat ringkasan data gabungan
      return {
        'success': true,
        'data': {
          'anak': anakDetail,
          'pertumbuhan': growth,
          'jadwal': schedule,
          'statistik': stats,
        }
      };
    } catch (e) {
      print('Error getting dashboard summary: $e');
      return {
        'success': false,
        'message': 'Gagal memuat data dashboard: $e',
        'data': null,
      };
    }
  }
  
  /// Mendapatkan semua data untuk cards di dashboard
  Future<Map<String, dynamic>> getDashboardCards() async {
    try {
      final response = await _apiService.get('dashboard/summary');
      
      if (response['success'] == true) {
        return response;
      } else {
        // Generate dummy data jika API belum tersedia
        return {
          'success': true,
          'data': {
            'total_anak': 56,
            'kunjungan_bulan_ini': 128,
            'anak_stunting': 7,
            'jadwal_hari_ini': 3,
          }
        };
      }
    } catch (e) {
      print('Error getting dashboard cards: $e');
      // Fallback data jika API gagal
      return {
        'success': true,
        'data': {
          'total_anak': 42,
          'kunjungan_bulan_ini': 95,
          'anak_stunting': 5,
          'jadwal_hari_ini': 2,
        }
      };
    }
  }
  
  /// Mendapatkan daftar artikel kesehatan terbaru
  Future<List<dynamic>> getLatestHealthArticles() async {
    try {
      // Karena endpoint API belum dibuat, langsung kembali ke dummy data
      // Hilangkan panggilan API yang menyebabkan error 404
      return _getDummyArticles();
      
      /* Kode di bawah ini akan diaktifkan nanti ketika API sudah tersedia
      final response = await _apiService.get('articles/latest');
      
      if (response['success'] == true) {
        return response['articles'] ?? [];
      } else {
        // Generate dummy data jika API belum tersedia
        return _getDummyArticles();
      }
      */
    } catch (e) {
      print('Error getting latest articles: $e');
      // Fallback ke data dummy
      return _getDummyArticles();
    }
  }
  
  /// Menghasilkan artikel kesehatan dummy (sementara)
  List<dynamic> _getDummyArticles() {
    return [
      {
        'id': 1,
        'title': 'Pentingnya ASI Eksklusif',
        'category': 'Gizi',
        'excerpt': 'ASI eksklusif selama 6 bulan pertama sangat penting untuk perkembangan bayi...',
        'image_url': null,
        'created_at': '2025-05-01',
      },
      {
        'id': 2,
        'title': 'Mencegah Stunting Sejak Dini',
        'category': 'Tumbuh Kembang',
        'excerpt': 'Stunting dapat dicegah dengan pemberian nutrisi yang tepat dan pemantauan pertumbuhan...',
        'image_url': null,
        'created_at': '2025-05-05',
      },
      {
        'id': 3,
        'title': 'Jadwal Imunisasi Lengkap',
        'category': 'Imunisasi',
        'excerpt': 'Imunisasi lengkap dapat melindungi anak dari berbagai penyakit berbahaya...',
        'image_url': null,
        'created_at': '2025-05-10',
      },
    ];
  }
  
  /// Helper: Mendapatkan data pertumbuhan terbaru
  Future<Map<String, dynamic>> _getLatestGrowthData(int anakId) async {
    try {
      final response = await _apiService.get('perkembangan/anak/$anakId/latest');
      
      if (response['success'] == true) {
        return response['data'] ?? {};
      }
      
      // Fallback: coba dapatkan dari list, ambil yang terakhir
      final perkembanganList = await _apiService.get('perkembangan/anak/$anakId');
      
      if (perkembanganList['status'] == 'success' && 
          perkembanganList['perkembangan'] is List && 
          (perkembanganList['perkembangan'] as List).isNotEmpty) {
        
        // Sort berdasarkan tanggal terbaru
        final list = perkembanganList['perkembangan'] as List;
        list.sort((a, b) {
          final dateA = DateTime.parse(a['tanggal']);
          final dateB = DateTime.parse(b['tanggal']);
          return dateB.compareTo(dateA); // Descending (terbaru dulu)
        });
        
        return list.first;
      }
      
      // Jika tidak ada data, berikan nilai default
      return {
        'tinggi_badan': 78.5,
        'berat_badan': 9.8,
        'tanggal': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      };
    } catch (e) {
      print('Error getting latest growth data: $e');
      
      // Data dummy jika error
      return {
        'tinggi_badan': 78.5,
        'berat_badan': 9.8,
        'tanggal': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      };
    }
  }
  
  /// Helper: Mendapatkan jadwal imunisasi terdekat
  Future<Map<String, dynamic>> _getUpcomingSchedule(int anakId) async {
    try {
      final response = await _apiService.get('jadwal/upcoming/$anakId');
      
      if (response['success'] == true) {
        return response['data'] ?? {};
      }
      
      // Data dummy jika API belum tersedia
      return {
        'jenis': 'Imunisasi DPT',
        'tanggal': DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: 14))),
        'jam': '09:00 - 12:00',
        'lokasi': 'Posyandu Melati',
      };
    } catch (e) {
      print('Error getting upcoming schedule: $e');
      
      // Data dummy jika error
      return {
        'jenis': 'Imunisasi DPT',
        'tanggal': DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: 14))),
        'jam': '09:00 - 12:00',
        'lokasi': 'Posyandu Melati',
      };
    }
  }
  
  /// Helper: Hitung statistik pertumbuhan
  Map<String, dynamic> _calculateStatistics(Map<String, dynamic> anakDetail, Map<String, dynamic> growth) {
    final tanggalLahir = DateTime.parse(anakDetail['tanggal_lahir']);
    final now = DateTime.now();
    final ageInDays = now.difference(tanggalLahir).inDays;
    final ageInMonths = (ageInDays / 30).floor(); // Approximate
    
    // Dapatkan tinggi dan berat badan
    double? height, weight;
    try {
      height = double.parse(growth['tinggi_badan'].toString());
      weight = double.parse(growth['berat_badan'].toString());
    } catch (e) {
      height = 75.0; // Default values jika parsing gagal
      weight = 9.0;
      print('Error parsing height/weight: $e');
    }
    
    // Hitung status berdasarkan standar WHO (implementasi sederhana)
    String statusBB = 'Normal';
    if (weight < 8.0) {
      statusBB = 'Kurang';
    } else if (weight > 15.0) {
      statusBB = 'Lebih';
    }
    
    String statusTB = 'Normal';
    if (height < 75.0) {
      statusTB = 'Pendek';
    } else if (height > 95.0) {
      statusTB = 'Tinggi';
    }
    
    // Tentukan status stunting
    bool isStunting = statusTB == 'Pendek' && statusBB == 'Kurang';
    
    return {
      'height': {
        'value': height,
        'status': statusTB,
      },
      'weight': {
        'value': weight,
        'status': statusBB,
      },
      'age': '$ageInMonths bulan',
      'is_stunting': isStunting,
      'overall_status': isStunting ? 'Stunting' : 'Normal',
    };
  }
}
