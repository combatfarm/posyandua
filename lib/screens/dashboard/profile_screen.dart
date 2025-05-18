import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/api_service.dart';
import '../../services/dashboard_service.dart';
import '../../models/profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../../services/perkembangan_service.dart';
import 'anak_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final ApiService _apiService = ApiService();
  final DashboardService _dashboardService = DashboardService();
  
  // User data
  String _userName = 'User';
  String _userInitials = 'U';
  String _childName = '';
  String _childAge = '';
  String _childGender = '';
  String _email = '';
  String _phone = '';
  String _address = '';
  String _nik = '';
  double _childHeight = 0;
  double _childWeight = 0;
  String _childStatus = 'Normal';
  bool _isChildStunting = false;
  int _childCount = 0;
  int _scheduleCount = 0;
  bool _isLoading = true;
  
  // Dashboard data
  Map<String, dynamic> _dashboardData = {};
  int? _selectedAnakId;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.1, 1.0, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.2, 0.8, curve: Curves.easeOut),
    ));
    
    // Clear any API cache first
    _apiService.clearChildCache();
    
    // Load data initially
    _loadUserData();
    _animationController.forward();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get data from SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      
      // Reset child count to 0
      _childCount = 0;
      await prefs.setInt('child_count', 0);
      
      // Basic user info
      String? userName = prefs.getString('nama_ibu');
      String? nik = prefs.getString('nik');
      int? userId = prefs.getInt('user_id');
      
      // Other profile info - Explicitly get from SharedPreferences first
      String? email = prefs.getString('email') ?? '';
      String? phone = prefs.getString('no_telp') ?? '';
      String? address = prefs.getString('alamat') ?? '';
      
      print('Initial data from SharedPreferences:');
      print('Email: $email');
      print('Phone: $phone');
      
      // Load dashboard data to get child info (same as dashboard screen)
      try {
        // Get last selected anak ID
        _selectedAnakId = await _dashboardService.getLastSelectedAnakId();
        
        if (_selectedAnakId != null) {
          // Get dashboard summary
          _dashboardData = await _dashboardService.getDashboardSummary(anakId: _selectedAnakId);
          print('Dashboard data loaded: ${_dashboardData.toString().substring(0, min(_dashboardData.toString().length, 200))}...');
          
          if (_dashboardData['success'] == true && _dashboardData['data'] != null) {
            // Extract child info from dashboard data
            final childData = _dashboardData['data']['anak'] ?? {};
            final statsData = _dashboardData['data']['statistik'] ?? {};
            final growthData = _dashboardData['data']['pertumbuhan'] ?? {};
            
            // Debug the data structure
            print('Child data: $childData');
            print('Stats data: $statsData');
            print('Growth data: $growthData');
            
            // First try to get direct data from perkembangan service to ensure consistency
            try {
              final perkembanganService = PerkembanganService();
              final perkembanganList = await perkembanganService.getPerkembanganByAnakId(_selectedAnakId!);
              
              if (perkembanganList.isNotEmpty) {
                // Sort by date descending to get the most recent
                perkembanganList.sort((a, b) {
                  final dateA = DateTime.parse(a['tanggal']);
                  final dateB = DateTime.parse(b['tanggal']);
                  return dateB.compareTo(dateA); // Most recent first
                });
                
                // Get the most recent record
                final latestRecord = perkembanganList.first;
                
                print('Using most recent perkembangan data: $latestRecord');
                _childHeight = double.tryParse(latestRecord['tinggi_badan'].toString()) ?? 0;
                _childWeight = double.tryParse(latestRecord['berat_badan'].toString()) ?? 0;
                
                print('Perkembangan height: $_childHeight, weight: $_childWeight');
              }
            } catch (e) {
              print('Error getting perkembangan data: $e, falling back to dashboard data');
            }
            
            // If we couldn't get perkembangan data, fallback to dashboard data
            if (_childHeight <= 0 || _childWeight <= 0) {
              // Update child info
              String childName = childData['nama_anak'] ?? '';
              String childAge = childData['usia'] ?? statsData['age'] ?? '';
              String childGender = childData['jenis_kelamin'] ?? '';
              
              // Extract height and weight - try all possible paths
              _childHeight = 0;
              _childWeight = 0;
              
              try {
                // Try directly from growth data (pertumbuhan)
                if (growthData is Map && growthData.isNotEmpty) {
                  if (growthData.containsKey('tinggi_badan')) {
                    var tinggi = growthData['tinggi_badan'];
                    var berat = growthData['berat_badan'];
                    
                    print('Found direct growth data: tinggi=$tinggi, berat=$berat');
                    _childHeight = double.tryParse(tinggi.toString()) ?? 0;
                    _childWeight = double.tryParse(berat.toString()) ?? 0;
                  }
                }
                
                // If not found, try from stats data
                if (_childHeight <= 0 && statsData is Map && statsData.isNotEmpty) {
                  if (statsData.containsKey('height') && statsData['height'] is Map) {
                    var heightData = statsData['height'];
                    var weightData = statsData['weight'];
                    
                    print('Found stats data: height=$heightData, weight=$weightData');
                    if (heightData.containsKey('value')) {
                      _childHeight = double.tryParse(heightData['value'].toString()) ?? 0;
                    }
                    
                    if (weightData != null && weightData.containsKey('value')) {
                      _childWeight = double.tryParse(weightData['value'].toString()) ?? 0;
                    }
                  }
                }
                
                // Last resort - check if values are directly in anak data
                if (_childHeight <= 0 && childData is Map && childData.isNotEmpty) {
                  if (childData.containsKey('tinggi_badan') || childData.containsKey('tinggi')) {
                    var tinggi = childData['tinggi_badan'] ?? childData['tinggi'];
                    var berat = childData['berat_badan'] ?? childData['berat'];
                    
                    print('Found child data: tinggi=$tinggi, berat=$berat');
                    _childHeight = double.tryParse(tinggi.toString()) ?? 0;
                    _childWeight = double.tryParse(berat.toString()) ?? 0;
                  }
                }
              } catch (e) {
                print('Error extracting height/weight: $e');
              }
              
              print('Final extracted values: height=$_childHeight, weight=$_childWeight');
              
              // Update local state with dashboard data
              _childName = childName;
              _childAge = childAge;
              _childGender = childGender;
            } else {
              // We already got data from perkembangan service, just update other fields
              String childName = childData['nama_anak'] ?? '';
              String childAge = childData['usia'] ?? statsData['age'] ?? '';
              String childGender = childData['jenis_kelamin'] ?? '';
              
              _childName = childName;
              _childAge = childAge;
              _childGender = childGender;
            }
            
            // Set child status
            final status = statsData.isNotEmpty && statsData['overall_status'] != null
                ? statsData['overall_status']
                : 'Normal';
            _childStatus = status;
            _isChildStunting = status.toLowerCase() == 'stunting';
          }
        }
      } catch (e) {
        print('Error loading dashboard data: $e');
      }
      
      // Try to get fresh user data from API if possible
      bool apiHasAnakData = false;
      try {
        if (nik != null && nik.isNotEmpty) {
          print('Fetching fresh user data from API');
          final userInfo = await _authService.getCurrentUser();
          
          print('API Response: ${userInfo.toString().substring(0, min(userInfo.toString().length, 500))}...');
          
          if (userInfo['success'] == true && userInfo['data'] != null) {
            final userData = userInfo['data'];
            
            // Update user data with better null checking
            userName = userData['nama'] ?? userData['nama_ibu'] ?? userName;
            
            // For email - check multiple possible field names and sources
            if (userData['email'] != null && userData['email'].toString().isNotEmpty) {
              email = userData['email'].toString();
              print('Email from API: $email');
              await prefs.setString('email', email);
            }
            
            // For phone - check multiple possible field names
            if (userData['no_telp'] != null && userData['no_telp'].toString().isNotEmpty) {
              phone = userData['no_telp'].toString();
              print('Phone from API (no_telp): $phone');
              await prefs.setString('no_telp', phone);
            } else if (userData['telepon'] != null && userData['telepon'].toString().isNotEmpty) {
              phone = userData['telepon'].toString();
              print('Phone from API (telepon): $phone');
              await prefs.setString('no_telp', phone);
            } else if (userData['nomor_telepon'] != null && userData['nomor_telepon'].toString().isNotEmpty) {
              phone = userData['nomor_telepon'].toString();
              print('Phone from API (nomor_telepon): $phone');
              await prefs.setString('no_telp', phone);
            }
            
            address = userData['alamat'] ?? address;
            
            // Update preferences with fresh data
            if (userName != null) await prefs.setString('nama_ibu', userName);
            if (address != null) await prefs.setString('alamat', address);
            
            // Check for child data in API response
            if (userData['anak'] != null && userData['anak'] is List) {
              // Update child count dengan memeriksa apakah array benar-benar berisi data
              if (userData['anak'].isNotEmpty) {
                _childCount = userData['anak'].length;
                await prefs.setInt('child_count', _childCount);
                apiHasAnakData = true;
                print('Updated child count from API: $_childCount');
              } else {
                // Array kosong, berarti tidak ada anak
                _childCount = 0;
                await prefs.setInt('child_count', 0);
                apiHasAnakData = true; // API memberikan data valid (array kosong)
                print('API reports no children (empty array)');
              }
            }
          }
        }
      } catch (e) {
        print('Error fetching user data from API: $e');
        // Continue with stored data
      }
      
      // If API has confirmed there are no children, don't try to get more data
      if (!apiHasAnakData && userId != null) {
        try {
          final List<dynamic> children = await _profileService.getChildren(userId: userId);
          if (children.isNotEmpty) {
            // Pastikan ini bukan dummy data
            bool isDummyData = children.length == 1 && 
                              (children[0]['nama']?.toString() == 'Data Dummy - API Error' || 
                               children[0]['nama']?.toString() == 'Error Data');
            
            if (!isDummyData) {
              _childCount = children.length;
              await prefs.setInt('child_count', _childCount);
              print('Updated child count from ProfileService: $_childCount');
            } else {
              print('Ignoring dummy data from ProfileService');
              _childCount = 0;
              await prefs.setInt('child_count', 0);
            }
          } else {
            // List kosong, berarti tidak ada anak
            _childCount = 0;
            await prefs.setInt('child_count', 0);
            print('ProfileService reports no children');
          }
        } catch (e) {
          print('Error fetching children via ProfileService: $e');
        }
      }
      
      // Double-check data after API call to ensure we have the latest
      if (email == null || email.isEmpty) {
        email = prefs.getString('email') ?? '';
      }
      
      if (phone == null || phone.isEmpty) {
        phone = prefs.getString('no_telp') ?? '';
      }
      
      // Update state with all the data we've gathered
      setState(() {
        _isLoading = false;
        _userName = userName ?? 'User';
        _nik = nik ?? '';
        _email = email ?? '';
        _phone = phone ?? '';
        _address = address ?? '';
                
        // Generate user initials
        if (_userName.isNotEmpty) {
          if (_userName.contains(' ')) {
            final nameParts = _userName.split(' ');
            if (nameParts.length >= 2) {
              _userInitials = '${nameParts[0][0]}${nameParts[1][0]}';
            } else {
              _userInitials = _userName.substring(0, _userName.length > 1 ? 2 : 1);
            }
          } else {
            _userInitials = _userName.substring(0, _userName.length > 1 ? 2 : 1);
          }
          _userInitials = _userInitials.toUpperCase();
        }
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Method to refresh data from API
  Future<void> _refreshData() async {
    // Clear any API cache to ensure fresh data
    _apiService.clearChildCache();
    
    // Get the latest selected anak ID
    _selectedAnakId = await _dashboardService.getLastSelectedAnakId();
    
    // If we have a selected anak, get the dashboard data
    if (_selectedAnakId != null) {
      // Get fresh dashboard data
      _dashboardData = await _dashboardService.getDashboardSummary(anakId: _selectedAnakId);
      print('Dashboard data refreshed');
    }
    
    // Load user data and update UI
    await _loadUserData();
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
      backgroundColor: Colors.grey[100],
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _refreshData,
            child: CustomScrollView(
              physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: screenSize.height * 0.35,
            pinned: true,
            stretch: true,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            backgroundColor: Colors.transparent,
        elevation: 0,
            leading: Padding(
              padding: EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.2),
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.teal.shade400,
                      Colors.teal.shade800,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Background patterns
                    Positioned(
                      top: -50,
                      right: -20,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -50,
                      left: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    
                    // Profile content
                    Center(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _slideAnimation.value),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Hero(
                                    tag: 'profile_pic',
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 15,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: screenSize.width * 0.15,
                                        backgroundColor: Colors.white.withOpacity(0.2),
                                        child: Text(
                                                _userInitials,
                                          style: TextStyle(
                                            fontSize: screenSize.width * 0.08,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                          _userName,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          offset: Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                            _childCount > 0 
                                              ? _childName.isNotEmpty 
                                                ? (_childCount > 1 
                                                    ? 'Ibu dari $_childName dan ${_childCount-1} anak lainnya' 
                                                    : 'Ibu dari $_childName')
                                                : 'Memiliki $_childCount anak'
                                              : 'Belum memiliki data anak',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
          },
        ),
      ),
                    ),
                  ],
                ),
              ),
              collapseMode: CollapseMode.parallax,
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(20),
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick stats
                    Row(
                      children: [
                              Expanded(
                                flex: 1,
                                child: _buildStatCard(
                          context: context,
                          title: 'Anak',
                                  value: '$_childCount',
                          icon: Icons.child_care,
                          color: Colors.blue,
                        ),
                        ),
                        SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: _buildStatCard(
                          context: context,
                          title: 'Jadwal',
                                  value: '$_scheduleCount',
                          icon: Icons.calendar_today,
                          color: Colors.orange,
                                ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    
                    // Personal info section
                    Text(
                      'Informasi Pribadi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Info cards
                    _buildProfileCard(
                      context: context,
                      title: 'Email',
                            content: _email.isNotEmpty ? _email : '-',
                      icon: Icons.email_outlined,
                      iconColor: Colors.red,
                    ),
                    SizedBox(height: 12),
                    _buildProfileCard(
                      context: context,
                      title: 'No. Handphone',
                            content: _phone.isNotEmpty ? _phone : '-',
                      icon: Icons.phone_outlined,
                      iconColor: Colors.green,
                    ),
                    SizedBox(height: 12),
                    _buildProfileCard(
                      context: context,
                      title: 'Alamat',
                            content: _address.isNotEmpty ? _address : '-',
                      icon: Icons.location_on_outlined,
                      iconColor: Colors.blue,
                    ),
                    SizedBox(height: 12),
                    _buildProfileCard(
                      context: context,
                      title: 'NIK',
                            content: _nik.isNotEmpty ? _maskNIK(_nik) : '-',
                      icon: Icons.credit_card_outlined,
                      iconColor: Colors.purple,
                    ),
                    SizedBox(height: 24),
                    
                          // Child info section - only show if there's child data
                          if (_childName.isNotEmpty) ...[
                    Text(
                      'Informasi Anak',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildChildCard(),
                    SizedBox(height: 24),
                          ],
                    
                    // Buttons section
                    _buildActionButtons(context),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                    color: Colors.grey[500],
                    size: 28,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Expanded(child: SizedBox(width: 40)),
              Expanded(
                child: IconButton(
                  icon: Icon(
                    Icons.person,
                    color: Colors.green[600],
                    size: 28,
                  ),
                  onPressed: null, // Sedang di halaman profile
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        elevation: 4,
        child: Icon(Icons.add_chart, size: 28),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnakScreen(),
            ),
          ).then((_) => _refreshData());
        },
        tooltip: 'Tambah Data Anak',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
  
  // Helper method to mask NIK for privacy
  String _maskNIK(String nik) {
    if (nik.length <= 8) return nik;
    return nik.substring(0, 8) + 'XXXXXXXX';
  }
  
  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    // Verifikasi nilai untuk menghindari tampilan yang tidak akurat
    String displayValue = value;
    if (title == 'Anak' && value != '0') {
      try {
        final intValue = int.parse(value);
        if (intValue > 10) {
          displayValue = '1';  // Tampilkan nilai yang lebih masuk akal
        }
      } catch (e) {
        // Gunakan nilai asli jika parsing gagal
      }
    }
    
    return Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
                    ),
                  ),
            SizedBox(height: 8),
                  Text(
            displayValue,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
      ),
    );
  }
  
  Widget _buildProfileCard({
    required BuildContext context,
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChildCard() {
    // Check if we have dashboard data
    if (_dashboardData.isEmpty || _dashboardData['success'] != true || _dashboardData['data'] == null || _childCount <= 0) {
      // No dashboard data or no children, show default/empty state
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.child_care,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Belum ada data anak",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Tambahkan data anak terlebih dahulu",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    
    // We have dashboard data, extract and format height and weight
    print('Building child card with height: $_childHeight, weight: $_childWeight');
    
    String heightStr;
    if (_childHeight > 0) {
      // Format to 1 decimal place if needed
      heightStr = _childHeight == _childHeight.roundToDouble() 
          ? _childHeight.round().toString() 
          : _childHeight.toStringAsFixed(1);
      heightStr += ' cm';
    } else {
      heightStr = "-";
    }
    
    String weightStr;
    if (_childWeight > 0) {
      // Format to 1 decimal place if needed
      weightStr = _childWeight == _childWeight.roundToDouble() 
          ? _childWeight.round().toString() 
          : _childWeight.toStringAsFixed(1);
      weightStr += ' kg';
    } else {
      weightStr = "-";
    }
    
    // Debug the values being displayed
    print('Displaying height: $heightStr, weight: $weightStr');
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.child_care,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _childName.isNotEmpty ? _childName : '-',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _childAge.isNotEmpty && _childGender.isNotEmpty 
                          ? '$_childAge • $_childGender' 
                          : (_childAge.isNotEmpty ? _childAge : (_childGender.isNotEmpty ? _childGender : '-')),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildChildStat('Tinggi', heightStr, Icons.height),
              _buildChildStat('Berat', weightStr, Icons.monitor_weight),
              _buildChildStat('Status', _childStatus, Icons.error_outline, isAlert: _isChildStunting),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildChildStat(String label, String value, IconData icon, {bool isAlert = false}) {
    bool isEmpty = value == "-" || value.isEmpty;
    
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isEmpty 
                ? Colors.grey.withOpacity(0.1) 
                : (isAlert ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1)),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isEmpty 
                ? Colors.grey 
                : (isAlert ? Colors.red : Colors.blue),
            size: 20,
          ),
        ),
        SizedBox(height: 6),
        Text(
          value == "-" ? "-" : value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isEmpty 
                ? Colors.grey 
                : (isAlert ? Colors.red : Colors.grey[800]),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: Icon(Icons.edit),
            label: Text('Edit Profil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _showEditProfileDialog(context),
          ),
        ),
        SizedBox(height: 16),
        Container(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: Icon(Icons.logout),
            label: Text('Keluar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red),
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _showLogoutDialog(context),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final navContext = Navigator.of(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout,
                color: Colors.red,
              ),
              SizedBox(width: 10),
              Text(
                "Konfirmasi",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            "Apakah Anda yakin ingin keluar dari aplikasi?",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                
                // Implement logout logic using the profile service
                try {
                  await _authService.logout();
                } catch (e) {
                  print('Logout error: $e');
                  // Continue with navigation even if API logout fails
                }
                
                // Gunakan navContext yang disiapkan di awal
                navContext.pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false, // This clears the navigation stack
                );
              },
              child: Text("Keluar"),
            ),
          ],
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final nameController = TextEditingController(text: _userName);
    final emailController = TextEditingController(text: _email);
    final phoneController = TextEditingController(text: _phone);
    final addressController = TextEditingController(text: _address);
    final nikController = TextEditingController(text: _nik);
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.edit, color: Colors.teal),
                  SizedBox(width: 10),
                  Text('Edit Profil'),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Ibu',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Email tidak valid';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          labelText: 'No. Handphone',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nomor handphone tidak boleh kosong';
                          }
                          if (value.length < 10) {
                            return 'Nomor handphone minimal 10 digit';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: addressController,
                        decoration: InputDecoration(
                          labelText: 'Alamat',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Alamat tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: nikController,
                        decoration: InputDecoration(
                          labelText: 'NIK',
                          prefixIcon: Icon(Icons.credit_card),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 16,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'NIK tidak boleh kosong';
                          }
                          if (value.length != 16) {
                            return 'NIK harus 16 digit';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: Text('Batal'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() => isLoading = true);
                      
                      try {
                        final profile = ProfileModel(
                          id: 0, // ID akan diambil dari API
                          name: nameController.text,
                          email: emailController.text,
                          phone: phoneController.text,
                          address: addressController.text,
                          nik: nikController.text,
                          children: [], // Tidak perlu mengirim data anak
                        );

                        await _profileService.updateProfile(profile);
                        
                        if (mounted) {
                          Navigator.pop(context, true); // Return true to indicate success
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Profil berhasil diperbarui'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _refreshData(); // Refresh data setelah update
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal memperbarui profil: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => isLoading = false);
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
