import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
import '../../services/anak_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/perkembangan_service.dart';
import '../../services/auth_service.dart';
import 'perkembangan_screen.dart';
import 'imunisasi_screen.dart';
import 'vitamin_screen.dart';
import 'stunting_screen.dart';
import 'profile_screen.dart';
import 'artikel_screen.dart';
import 'penjadwalan_screen.dart';
import 'anak_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:posyandu/services/jadwal_service.dart';
import 'package:posyandu/models/jadwal_model.dart';
import 'package:intl/intl.dart';


class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentIndex = 0;
  
  final DashboardService _dashboardService = DashboardService();
  final AnakService _anakService = AnakService();
  final AuthService _authService = AuthService();
  final JadwalService _jadwalService = JadwalService();
  //final PerkembanganService _perkembanganService = PerkembanganService();
  
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  List<dynamic> _anakList = [];
  int? _selectedAnakId;
  String _errorMessage = '';
  String _motherName = 'User';
  String _motherInitials = 'IB';
  JadwalModel? _nearestJadwal;
  bool _isLoadingNearest = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.1, 1.0, curve: Curves.easeOut),
    ));
    
    _animationController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserInfo();
      _loadDashboardData();
      _loadNearestJadwal();
    });
  }
  
  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // First try to load NIK from preferences
      String? nik = prefs.getString('nik');
      
      if (nik != null && nik.isNotEmpty) {
        try {
          print('Fetching user data directly from API using NIK: $nik');
          
          // Get fresh data from the API
          final userInfo = await _authService.getCurrentUser();
          
          if (userInfo['success'] == true && userInfo['data'] != null) {
            final userData = userInfo['data'];
            
            // Mendapatkan nama pengguna sesuai dengan struktur data API
            String nama = '';
            
            if (userData['nama'] != null && userData['nama'].toString().isNotEmpty) {
              nama = userData['nama'].toString();
            } else if (userData['nama_ibu'] != null) {
              nama = userData['nama_ibu'].toString();
            }
            
            if (nama.isNotEmpty) {
              // Hapus kata 'Ibu' jika sudah ada di awal nama
              if (nama.startsWith('Ibu ')) {
                nama = nama.substring(4);
              }
              
              setState(() {
                _motherName = nama;
                
                // Generate initials from the name
                if (nama.contains(' ')) {
                  final nameParts = nama.split(' ');
                  if (nameParts.length >= 2) {
                    _motherInitials = '${nameParts[0][0]}${nameParts[1][0]}';
                  } else {
                    _motherInitials = nama.substring(0, min(2, nama.length));
                  }
                } else {
                  _motherInitials = nama.substring(0, min(2, nama.length));
                }
                
                // Ensure initials are uppercase
                _motherInitials = _motherInitials.toUpperCase();
              });
              
              // Save user data for future use
              await prefs.setString('nama_ibu', nama);
              print('Updated user data: $nama');
            }
            return;
          }
        } catch (e) {
          print('Error fetching data from API: $e');
          // Fall back to stored data
        }
      }
      
      // If we get here, either API call failed or no NIK found
      // Fall back to stored data
      String motherName = prefs.getString('nama_ibu') ?? '';
      
      if (motherName.isNotEmpty) {
        // Hapus kata 'Ibu' jika sudah ada di awal nama
        if (motherName.startsWith('Ibu ')) {
          motherName = motherName.substring(4);
        }
        
        setState(() {
          _motherName = motherName;
          
          // Generate initials
          if (motherName.contains(' ')) {
            final nameParts = motherName.split(' ');
            if (nameParts.length >= 2) {
              _motherInitials = '${nameParts[0][0]}${nameParts[1][0]}';
            } else {
              _motherInitials = motherName.substring(0, min(2, motherName.length));
            }
          } else {
            _motherInitials = motherName.substring(0, min(2, motherName.length));
          }
          
          _motherInitials = _motherInitials.toUpperCase();
        });
      }
      
      print('Loaded mother name: $_motherName, initials: $_motherInitials');
    } catch (e) {
      print('Error loading user info: $e');
      setState(() {
        _motherName = 'User';
        _motherInitials = 'IB';
      });
    }
  }
  
  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final anakListFuture = _anakService.getAnakList().timeout(
        Duration(seconds: 2),
        onTimeout: () {
          print('Timeout getting anak list, using empty list');
          return [];
        }
      );
      
      final selectedIdFuture = _dashboardService.getLastSelectedAnakId();
      
      final results = await Future.wait([anakListFuture, selectedIdFuture]);
      
      final anakList = results[0] as List<dynamic>;
      final selectedId = results[1] as int?;
      
      int? finalSelectedId = selectedId;
      if (finalSelectedId == null || !anakList.any((anak) => anak['id'] == finalSelectedId)) {
        finalSelectedId = anakList.isNotEmpty ? anakList[0]['id'] : null;
        
        if (finalSelectedId != null) {
          _dashboardService.setSelectedAnak(finalSelectedId);
        }
      }
      
      Map<String, dynamic> dashboardData = {};
      if (finalSelectedId != null) {
        try {
          // First try loading from perkembangan service directly to match what perkembangan screen shows
          final perkembanganService = PerkembanganService();
          final perkembanganData = await perkembanganService.getPerkembanganByAnakId(finalSelectedId)
            .timeout(Duration(seconds: 3), onTimeout: () {
              print('Timeout getting perkembangan data');
              return [];
            });
            
          dashboardData = await _dashboardService.getDashboardSummary(anakId: finalSelectedId)
            .timeout(Duration(seconds: 2), onTimeout: () {
              print('Timeout getting dashboard summary, using dummy data');
              return _createDummyDashboardData(finalSelectedId!);
            });
          
          if (dashboardData.isEmpty || dashboardData['success'] != true) {
            dashboardData = _createDummyDashboardData(finalSelectedId);
          }
          
          // If we successfully loaded perkembangan data, update the pertumbuhan field
          if (perkembanganData.isNotEmpty) {
            try {
              // Sort by date descending to get the most recent record
              perkembanganData.sort((a, b) {
                final dateA = DateTime.parse(a['tanggal']);
                final dateB = DateTime.parse(b['tanggal']);
                return dateB.compareTo(dateA); // Most recent first
              });
              
              // Update dashboard data with the most recent perkembangan record
              final latestRecord = perkembanganData.first;
              
              // Make sure dashboardData is properly structured
              if (dashboardData['data'] == null) {
                dashboardData['data'] = {};
              }
              
              dashboardData['data']['pertumbuhan'] = latestRecord;
              print('Updated dashboard with latest perkembangan: ${latestRecord['tinggi_badan']} cm, ${latestRecord['berat_badan']} kg');
            } catch (e) {
              print('Error updating dashboard with perkembangan data: $e');
            }
          }
        } catch (e) {
          print("Error loading dashboard summary: $e");
          dashboardData = _createDummyDashboardData(finalSelectedId);
        }
      }
      
      if (!mounted) return;
      
      setState(() {
        _anakList = anakList;
        _selectedAnakId = finalSelectedId;
        _dashboardData = dashboardData;
        _isLoading = false;
      });
      
      Future.delayed(Duration(seconds: 3), () {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
      });
      
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat data: $e';
      });
    }
  }
  
  Map<String, dynamic> _createDummyDashboardData(int anakId) {
    try {
      final anak = _anakList.firstWhere((element) => element['id'] == anakId, 
                   orElse: () => {'id': anakId, 'nama_anak': 'Anak', 'jenis_kelamin': 'Laki-laki', 'tanggal_lahir': DateTime.now().subtract(Duration(days: 365)).toString()});
      
      return {
        'success': true,
        'data': {
          'anak': anak,
          'pertumbuhan': {
            'tinggi_badan': 75.0,
            'berat_badan': 9.0,
            'tanggal': DateTime.now().toString(),
          },
          'jadwal': {
            'jenis': 'Imunisasi DPT',
            'tanggal': DateTime.now().add(Duration(days: 14)).toString(),
            'jam': '09:00 - 12:00',
            'lokasi': 'Posyandu Melati',
          },
          'statistik': {
            'height': {
              'value': 75.0,
              'status': 'Normal',
            },
            'weight': {
              'value': 9.0,
              'status': 'Normal',
            },
            'age': '12 bulan',
            'is_stunting': false,
            'overall_status': 'Normal',
          },
        }
      };
    } catch (e) {
      print('Error creating dummy data: $e');
      return {
        'success': true,
        'data': {
          'anak': {'nama_anak': 'Anak', 'jenis_kelamin': 'Laki-laki'},
          'statistik': {
            'height': {'value': 75.0, 'status': 'Normal'},
            'weight': {'value': 9.0, 'status': 'Normal'},
            'age': '12 bulan',
            'overall_status': 'Normal',
          }
        }
      };
    }
  }
  
  Future<void> _selectAnak(int anakId) async {
    if (_selectedAnakId == anakId) return;
    
    setState(() {
      _isLoading = true;
      _selectedAnakId = anakId;
    });
    
    try {
      await _dashboardService.setSelectedAnak(anakId);
      
      // Load data directly from the dashboard service
      final dashboardData = await _dashboardService.getDashboardSummary(anakId: anakId);
      
      // Also load perkembangan data to ensure we're showing the same data as the perkembangan screen
      final perkembanganService = PerkembanganService();
      final perkembanganData = await perkembanganService.getPerkembanganByAnakId(anakId);
      
      // If we have perkembangan data, update the growth data in the dashboard
      if (perkembanganData.isNotEmpty) {
        // Sort to get the most recent record
        perkembanganData.sort((a, b) {
          final dateA = DateTime.parse(a['tanggal']);
          final dateB = DateTime.parse(b['tanggal']);
          return dateB.compareTo(dateA); // Most recent first
        });
        
        // Update dashboard data
        final latestRecord = perkembanganData.first;
        if (dashboardData['data'] == null) {
          dashboardData['data'] = {};
        }
        dashboardData['data']['pertumbuhan'] = latestRecord;
      }
      
      setState(() {
        _dashboardData = dashboardData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error selecting anak: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat data: $e';
      });
    }
  }
  
  Future<void> _loadNearestJadwal() async {
    if (_selectedAnakId == null) return;
    setState(() { _isLoadingNearest = true; });
    try {
      final nearest = await _jadwalService.getNearestJadwalForChild(_selectedAnakId!);
      setState(() {
        _nearestJadwal = nearest;
        _isLoadingNearest = false;
      });
    } catch (e) {
      setState(() {
        _nearestJadwal = null;
        _isLoadingNearest = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadNearestJadwal();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh all data when pulled down
          await _loadUserInfo();
          await _loadDashboardData();
          await _loadNearestJadwal();
        },
        child: CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: screenSize.height * 0.25,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF4CAF50),
                      Color(0xFF2E7D32),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -30,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: -70,
                      bottom: -40,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FadeTransition(
                                      opacity: _fadeAnimation,
                                      child: Text(
                                          'Halo, Ibu $_motherName',
                                        style: TextStyle(
                                          fontSize: screenSize.width * 0.06,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black26,
                                              offset: Offset(0, 2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    FadeTransition(
                                      opacity: _fadeAnimation,
                                      child: Text(
                                        'Selamat datang kembali',
                                        style: TextStyle(
                                          fontSize: screenSize.width * 0.035,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProfileScreen(),
                                      ),
                                      ).then((_) {
                                        // Ketika kembali dari ProfileScreen, refresh data dashboard
                                        _loadUserInfo();
                                        _loadDashboardData();
                                        
                                        // Reset index ke home
                                        setState(() {
                                          _currentIndex = 0;
                                        });
                                      });
                                  },
                                  child: Hero(
                                    tag: 'profile_pic',
                                    child: Container(
                                      padding: EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: screenSize.width * 0.055,
                                        backgroundColor: Colors.white.withOpacity(0.2),
                                        child: Text(
                                            _motherInitials,
                                          style: TextStyle(
                                            fontSize: screenSize.width * 0.04,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              collapseMode: CollapseMode.parallax,
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(10),
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildChildCard(screenSize),
                    SizedBox(height: screenSize.height * 0.025),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Menu Utama',
                          style: TextStyle(
                            fontSize: screenSize.width * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenSize.height * 0.01),
                    
                    GridView.count(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 1.2,
                      children: [
                          DashboardCard(
                            title: 'Data Anak',
                            icon: Icons.child_care,
                            color: Colors.green,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AnakScreen()),
                            ),
                          ),
                        DashboardCard(
                          title: 'Perkembangan',
                          icon: Icons.trending_up,
                          color: Colors.blue,
                            onTap: () async {
                              try {
                                final AnakService anakService = AnakService();
                                final anakList = await anakService.getAnakList();
                                
                                if (anakList.isNotEmpty) {
                                  final anakId = anakList[0]['id'];
                                  Navigator.push(
                            context,
                                    MaterialPageRoute(builder: (context) => PerkembanganScreen(anakId: anakId)),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Tidak ada data anak. Silakan tambahkan data anak terlebih dahulu.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              } catch (e) {
                                print('Error getting anak data: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Terjadi kesalahan. Silakan coba lagi.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                        ),
                        DashboardCard(
                          title: 'Imunisasi',
                          icon: Icons.vaccines,
                          color: Colors.purple,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ImunisasiScreen(anakId: _selectedAnakId, anakName: _anakList.firstWhere((a) => a['id'] == _selectedAnakId)['nama_anak'])),
                          ),
                        ),
                        DashboardCard(
                          title: 'Vitamin',
                          icon: Icons.medication,
                          color: Colors.orange,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => VitaminScreen(
                              anakId: _selectedAnakId, 
                              anakName: _anakList.firstWhere((a) => a['id'] == _selectedAnakId)['nama_anak'],
                            )),
                          ),
                        ),
                        DashboardCard(
                          title: 'Stunting',
                          icon: Icons.height,
                          color: Colors.red,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => StuntingScreen()),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenSize.height * 0.025),
                    
                    _buildNextScheduleCard(screenSize, context),
                    SizedBox(height: screenSize.height * 0.025),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Artikel Kesehatan',
                          style: TextStyle(
                            fontSize: screenSize.width * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ArtikelScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Lihat Semua',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenSize.height * 0.01),
                    
                    _buildArticleList(screenSize),
                    SizedBox(height: screenSize.height * 0.01),
                  ],
                ),
              ),
            ),
          ),
        ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: EdgeInsets.only(top: 30),
        height: 65,
        width: 65,
        child: FloatingActionButton(
          backgroundColor: Colors.green[600],
          child: Icon(
            Icons.calendar_month,
            size: 30,
          ),
          elevation: 4,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PenjadwalanScreen(anakId: _selectedAnakId!)),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 8,
        child: Container(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: IconButton(
                  icon: Icon(
                    Icons.home,
                    color: _currentIndex == 0 ? Colors.green[600] : Colors.grey[500],
                    size: 28,
                  ),
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                    });
                  },
                ),
              ),
              Expanded(child: SizedBox(width: 40)),
              Expanded(
                child: IconButton(
                  icon: Icon(
                    Icons.person,
                    color: _currentIndex == 1 ? Colors.green[600] : Colors.grey[500],
                    size: 28,
                  ),
            onPressed: () {
                    setState(() {
                      _currentIndex = 1;
                    });
                    
              Navigator.push(
                context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(),
                      ),
                    ).then((_) {
                      // Ketika kembali dari ProfileScreen, refresh data dashboard
                      _loadUserInfo();
                      _loadDashboardData();
                      
                      // Reset index ke home
                      setState(() {
                        _currentIndex = 0;
                      });
                    });
            },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildCard(Size screenSize) {
    if (_isLoading) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
      width: double.infinity,
          height: 120,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
                Colors.blue[400]!,
                Colors.blue[600]!,
          ],
        ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    
    if (_errorMessage.isNotEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _errorMessage,
            style: TextStyle(color: Colors.red[800]),
          ),
        ),
      );
    }
    
    if (_anakList.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Belum ada data anak',
                style: TextStyle(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AnakScreen()),
                  );
                },
                child: Text('Tambah Data Anak'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Mendapatkan data anak
    final childData = _dashboardData['success'] == true && _dashboardData['data'] != null
        ? _dashboardData['data']['anak'] ?? {}
        : {};
        
    final statsData = _dashboardData['success'] == true && _dashboardData['data'] != null
        ? _dashboardData['data']['statistik'] ?? {}
        : {};

    final growthData = _dashboardData['success'] == true && _dashboardData['data'] != null
        ? _dashboardData['data']['pertumbuhan'] ?? {}
        : {};
        
    // Mendapatkan data untuk ditampilkan
    final childName = childData['nama_anak'] ?? 'Nama Anak';
    final childAge = childData['usia'] ?? statsData['age'] ?? '0 bulan';
    final childGender = childData['jenis_kelamin'] == 'Laki-laki' ? 'L' : 'P';
    
    // Format data pertumbuhan, pastikan kita menggunakan data yang sama dengan di screen perkembangan
    String height = '0';
    String weight = '0';
    
    try {
      // Debug:
      print('Growth data type: ${growthData.runtimeType}');
      print('Growth data: $growthData');
    
      if (growthData is Map && growthData.isNotEmpty) {
        // Handle format data yang berbeda
        if (growthData.containsKey('tinggi_badan')) {
          height = growthData['tinggi_badan']?.toString() ?? '0';
          weight = growthData['berat_badan']?.toString() ?? '0';
        } else if (statsData.isNotEmpty && 
                 statsData.containsKey('height') && 
                 statsData['height'] != null && 
                 statsData['height'].containsKey('value')) {
          // Fallback ke statistik jika tidak ada di data pertumbuhan
          height = statsData['height']['value'].toString();
          weight = statsData['weight']['value'].toString();
        }
      } else if (growthData is List && growthData.isNotEmpty) {
        // Jika API mengembalikan array, ambil data terbaru (index terakhir)
        final latestGrowth = growthData.first; // Karena sudah disort di _loadDashboardData
        height = latestGrowth['tinggi_badan']?.toString() ?? '0';
        weight = latestGrowth['berat_badan']?.toString() ?? '0';
      } else if (statsData.isNotEmpty) {
        // Fallback ke statistik
        height = statsData['height'] != null && statsData['height']['value'] != null
            ? statsData['height']['value'].toString()
            : '0';
        weight = statsData['weight'] != null && statsData['weight']['value'] != null
            ? statsData['weight']['value'].toString()
            : '0';
      }
      
      // Format angka untuk tampilan yang lebih baik
      try {
        final heightVal = double.parse(height);
        height = heightVal.toStringAsFixed(1);
        if (height.endsWith('.0')) {
          height = height.substring(0, height.length - 2);
        }
      } catch (e) {
        // Biarkan nilai asli jika gagal parsing
      }
      
      try {
        final weightVal = double.parse(weight);
        weight = weightVal.toStringAsFixed(1);
        if (weight.endsWith('.0')) {
          weight = weight.substring(0, weight.length - 2);
        }
      } catch (e) {
        // Biarkan nilai asli jika gagal parsing
      }
    } catch (e) {
      print('Error processing growth data: $e');
    }
    
    // Status stunting
    final status = statsData.isNotEmpty && statsData['overall_status'] != null
        ? statsData['overall_status']
        : 'Normal';
    final isStunting = status.toLowerCase() == 'stunting';
    
    // Return the child card
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.blue[400],
          borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Header dengan nama anak dan dropdown
              Container(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      radius: 26,
                child: Icon(
                        Icons.person_outline,
                  color: Colors.white,
                        size: 30,
                      ),
                ),
              ),
                  SizedBox(width: 12),
                  
                  // Nama dan usia
                  Expanded(
                    child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                children: [
                        Flexible(
                          child: Container(
                            width: double.infinity,
                            child: Text(
                              childName,
                    style: TextStyle(
                                fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                                height: 1.2,
                    ),
                              overflow: TextOverflow.visible,
                              maxLines: 3,
                              softWrap: true,
                  ),
                          ),
                        ),
                        SizedBox(height: 4),
                  Text(
                          '$childAge ($childGender)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
                  ),
                  
                  // Dropdown selector
                  if (_anakList.length > 1)
                    Container(
                      height: 34,
                      padding: EdgeInsets.only(left: 8),
                      margin: EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isDense: true,
                          value: _selectedAnakId,
                          icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                          dropdownColor: Colors.blue[500],
                          items: _anakList.map((anak) {
                            final name = anak['nama_anak'] ?? '';
                            // Truncate long names in the dropdown
                            final displayName = name.length > 15 
                                ? name.substring(0, 12) + '...' 
                                : name;
                                
                            return DropdownMenuItem<int>(
                              value: anak['id'],
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _selectAnak(value);
                            }
                          },
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
              ),
            ],
          ),
            ),
            
            // Status boxes
            Container(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Box pertama: 3 status
          Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
                      _buildChildStatBox('Tinggi', '$height cm', boxType: 'height'),
                      _buildChildStatBox('Berat', '$weight kg', boxType: 'weight'),
                      _buildChildStatBox('Status', status, boxType: 'status', isStunting: isStunting),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Tombol Cek Stunting
                  SizedBox(
                    width: screenSize.width * 0.6,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StuntingScreen(),
                          ),
                        );
                      },
                      icon: Icon(Icons.medical_services, size: 20),
                      label: Text(
                        'Cek Stunting',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 1,
                      ),
                    ),
                  ),
            ],
              ),
          ),
        ],
        ),
      ),
    );
  }
  
  Widget _buildChildStatBox(String label, String value, {required String boxType, bool isStunting = false}) {
    // Disesuaikan dengan gambar, dengan tiga jenis kotak
    Color boxColor = boxType == 'status' 
        ? (isStunting ? Color(0xFF7986CB).withOpacity(0.5) : Colors.white.withOpacity(0.2))
        : Colors.white.withOpacity(0.2);
    
    // Format nilai jika numeric untuk menghindari menampilkan nilai seperti "0.0"
    String displayValue = value;
    if (boxType != 'status') {
      try {
        final numValue = double.parse(value);
        if (numValue == 0) {
          displayValue = "-";
        } else {
          // Format to at most 1 decimal place if needed
          displayValue = numValue == numValue.toInt() 
              ? numValue.toInt().toString()
              : numValue.toStringAsFixed(1);
        }
      } catch (e) {
        // If parsing fails, just use the original value
        displayValue = value;
      }
    }
    
    Widget icon;
    
    // Tentukan icon berdasarkan jenis kotak
    if (boxType == 'height') {
      icon = Icon(
        Icons.swap_vert,
        color: Colors.white,
        size: 24,
      );
    } else if (boxType == 'weight') {
      icon = Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.circle,
          color: Colors.blue[400],
          size: 14,
        ),
      );
    } else {
      icon = Icon(
        Icons.error_outline,
        color: Colors.white,
        size: 24,
      );
    }
    
    return Container(
      width: 90,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            icon,
          SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
                ),
              ),
          SizedBox(height: 2),
              Text(
            displayValue,
                style: TextStyle(
              fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildNextScheduleCard(Size screenSize, BuildContext context) {
    if (_isLoadingNearest || _selectedAnakId == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_nearestJadwal == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Text('Tidak ada jadwal terdekat', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
      );
    }
    final jadwal = _nearestJadwal!;
    final jenisColor = _getJenisColor(jadwal.jenis ?? '-');
    final solidColor = _getJenisSolidColor(jadwal.jenis ?? '-');
    return AnimatedOpacity(
      opacity: 1,
      duration: Duration(milliseconds: 700),
      curve: Curves.easeIn,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(18),
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: jenisColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: solidColor.withOpacity(0.15),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: solidColor.withOpacity(0.18),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(_getJenisIcon(jadwal.jenis ?? '-'), color: solidColor, size: 36),
            ),
            SizedBox(width: 16),
            // Info utama
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: solidColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule, color: Colors.white, size: 13),
                            SizedBox(width: 4),
                            Text('Jadwal Terdekat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(jadwal.nama ?? '-', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white, letterSpacing: 0.1)),
                  SizedBox(height: 3),
                  Text(jadwal.jenis ?? '-', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.92), fontWeight: FontWeight.w500)),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 13, color: Colors.white.withOpacity(0.93)),
                      SizedBox(width: 3),
                      Flexible(child: Text(jadwal.tanggal != null ? DateFormat('dd MMM yyyy').format(jadwal.tanggal) : '-', style: TextStyle(fontSize: 13, color: Colors.white), overflow: TextOverflow.ellipsis)),
                      SizedBox(width: 8),
                      Icon(Icons.access_time, size: 13, color: Colors.white.withOpacity(0.93)),
                      SizedBox(width: 3),
                      Flexible(child: Text(jadwal.waktu ?? '-', style: TextStyle(fontSize: 13, color: Colors.white), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 13, color: Colors.white.withOpacity(0.93)),
                      SizedBox(width: 3),
                      Flexible(child: Text('Posyandu Mahoni 54', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  if (jadwal.keterangan != null && jadwal.keterangan!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(jadwal.keterangan!, style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleList(Size screenSize) {
    return FutureBuilder<List<dynamic>>(
      future: _dashboardService.getLatestHealthArticles().timeout(
        Duration(seconds: 3),
        onTimeout: () {
          print('Timeout getting articles, using fallback data');
          return [
      {
              'id': 1,
        'title': 'Pentingnya ASI Eksklusif',
        'category': 'Gizi',
              'excerpt': 'ASI eksklusif selama 6 bulan pertama sangat penting...',
            }
          ];
        },
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  width: screenSize.width * 0.6,
                  margin: EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey[200],
                  ),
                );
              },
            ),
          );
        }
        
        if (snapshot.hasError) {
          print('Error in article FutureBuilder: ${snapshot.error}');
          return Center(
            child: Text('Tidak dapat memuat artikel'),
          );
        }
        
        final articles = snapshot.data ?? [];
        
        if (articles.isEmpty) {
          return Center(
            child: Text('Tidak ada artikel tersedia'),
          );
        }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          
          return Container(
            width: screenSize.width * 0.6,
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                        color: _getCategoryColor(article['category']).withOpacity(0.2),
                  ),
                  child: Center(
                    child: Icon(
                          getCategoryIcon(article['category']),
                      size: 40,
                          color: _getCategoryColor(article['category']),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                              color: _getCategoryColor(article['category']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                              article['category'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                                color: _getCategoryColor(article['category']),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                            article['title'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
      },
    );
  }
  
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Gizi':
        return Colors.orange;
      case 'Imunisasi':
        return Colors.purple;
      case 'Tumbuh Kembang':
        return Colors.blue;
      default:
        return Colors.teal;
    }
  }

  IconData _getJenisIcon(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'imunisasi':
        return Icons.vaccines;
      case 'vitamin':
        return Icons.medication;
      case 'pemeriksaan rutin':
        return Icons.medical_services;
      default:
        return Icons.event;
    }
  }

  Color _getJenisSolidColor(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'imunisasi':
        return Colors.purple.shade400;
      case 'vitamin':
        return Colors.orange.shade400;
      case 'pemeriksaan rutin':
        return Colors.blue.shade400;
      default:
        return Colors.teal.shade400;
    }
  }

  Color _getJenisColor(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'imunisasi':
        return Colors.purple.shade400;
      case 'vitamin':
        return Colors.orange.shade400;
      case 'pemeriksaan rutin':
        return Colors.blue.shade400;
      default:
        return Colors.teal.shade400;
    }
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                icon,
                  color: color,
                  size: 32,
                ),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData getCategoryIcon(String category) {
  switch (category) {
    case 'Gizi':
      return Icons.restaurant;
    case 'Imunisasi':
      return Icons.vaccines;
    case 'Tumbuh Kembang':
      return Icons.child_care;
    default:
      return Icons.healing;
  }
}

void _navigateToImunisasiScreen(BuildContext context, int anakId, String anakName) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ImunisasiScreen(
        anakId: anakId,
        anakName: anakName,
      ),
    ),
  );
}

Widget _buildChildrenList(BuildContext context, List<dynamic> children) {
  return ListView.builder(
    itemCount: children.length,
    itemBuilder: (context, index) {
      final child = children[index];
      return Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          leading: CircleAvatar(
            child: Text(child['nama_anak']?.substring(0, 1) ?? 'A'),
          ),
          title: Text(child['nama_anak'] ?? 'Anak'),
          subtitle: Text('Usia: ${child['usia'] ?? 'N/A'}'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Simpan anak terpilih ke SharedPreferences
            _saveSelectedChild(child['id'], child['nama_anak']);
            
            // Navigasi ke layar imunisasi dengan ID dan nama anak
            _navigateToImunisasiScreen(
              context,
              child['id'],
              child['nama_anak'],
            );
          },
        ),
      );
    },
  );
}

Future<void> _saveSelectedChild(int anakId, String anakName) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('selected_anak_id', anakId);
  await prefs.setString('anak_name_$anakId', anakName);
}
