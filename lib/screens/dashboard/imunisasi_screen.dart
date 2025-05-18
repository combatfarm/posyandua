import 'package:flutter/material.dart';
import '../../models/imunisasi_model.dart';
import '../../controllers/imunisasi_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImunisasiScreen extends StatefulWidget {
  final int? anakId;
  final String? anakName;
  
  ImunisasiScreen({this.anakId, this.anakName});
  
  @override
  _ImunisasiScreenState createState() => _ImunisasiScreenState();
}

class _ImunisasiScreenState extends State<ImunisasiScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late ImunisasiController _imunisasiController;
  bool _isLoading = true;
  String? _error;
  int? _selectedAnakId;
  String _anakName = "";
  String _anakAge = "";
  
  @override
  void initState() {
    super.initState();
    _imunisasiController = ImunisasiController();
    
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
    
    if (widget.anakName != null && widget.anakName!.isNotEmpty) {
      _anakName = widget.anakName!;
    }
    
    _loadData();
    _animationController.forward();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      int anakId = widget.anakId ?? await _getSelectedAnakId();
      _selectedAnakId = anakId;
      
      if (_anakName.isEmpty) {
        await _getAnakInfo(anakId);
      }
      
      await _imunisasiController.loadImunisasiForAnak(anakId);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (e.toString().contains('Data anak tidak ditemukan')) {
            _error = 'Data anak tidak ditemukan. Silakan pilih anak lain.';
          } else {
            _error = 'Error loading data: $e';
          }
        });
      }
    }
  }
  
  Future<void> _getAnakInfo(int anakId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final anakName = prefs.getString('anak_name_$anakId');
      final anakAge = prefs.getString('anak_age_$anakId');
      
      if (anakName != null && anakName.isNotEmpty) {
        setState(() {
          _anakName = anakName;
          _anakAge = anakAge ?? '';
        });
        return;
      }
      
      try {
        final anakData = await _imunisasiController.getAnakById(anakId);
        print('Retrieved anak data: $anakData');
        
        if (anakData != null) {
          String nama = '';
          if (anakData.containsKey('nama_anak')) {
            nama = anakData['nama_anak'];
          }
          
          // Debug age data
          print('Age data found: ${anakData['tanggal_lahir']} | ${anakData['umur_bulan']} | ${anakData['umur_hari']}');
          
          // Get age data
          String usia = '';
          if (anakData.containsKey('umur_bulan') && anakData['umur_bulan'] != null) {
            final umurBulan = anakData['umur_bulan'];
            usia = '$umurBulan bulan';
            print('Using umur_bulan: $usia');
          } else if (anakData.containsKey('umur_hari') && anakData['umur_hari'] != null) {
            final umurHari = anakData['umur_hari'];
            if (umurHari >= 30) {
              final bulan = (umurHari / 30).floor();
              usia = '$bulan bulan';
            } else {
              usia = '$umurHari hari';
            }
            print('Using umur_hari: $usia');
          } else if (anakData.containsKey('tanggal_lahir') && anakData['tanggal_lahir'] != null) {
            try {
              final birthDate = DateTime.parse(anakData['tanggal_lahir']);
              final now = DateTime.now();
              final difference = now.difference(birthDate);
              final days = difference.inDays;
              
              if (days >= 30) {
                final months = (days / 30).floor();
                if (months >= 12) {
                  final years = (months / 12).floor();
                  final remainingMonths = months % 12;
                  if (remainingMonths > 0) {
                    usia = '$years tahun $remainingMonths bulan';
                  } else {
                    usia = '$years tahun';
                  }
                } else {
                  usia = '$months bulan';
                }
              } else {
                usia = '$days hari';
              }
              print('Calculated from tanggal_lahir: $usia');
            } catch (e) {
              print('Error calculating age from birthdate: $e');
            }
          }
          
          setState(() {
            _anakName = nama.isNotEmpty ? nama : "Anak $anakId";
            _anakAge = usia;
          });
          
          await prefs.setString('anak_name_$anakId', _anakName);
          await prefs.setString('anak_age_$anakId', usia);
          
          print('Saved anak data: $_anakName, $_anakAge');
          return;
        }
      } catch (apiError) {
        print('Error mengambil data anak dari API: $apiError');
      }
      
      setState(() {
        _anakName = "Anak $anakId";
        _anakAge = "";
      });
    } catch (e) {
      print('Error mendapatkan info anak: $e');
      setState(() {
        _anakName = "Anak $anakId";
        _anakAge = "";
      });
    }
  }
  
  Future<int> _getSelectedAnakId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final anakId = prefs.getInt('selected_anak_id');
      
      if (anakId != null) {
        return anakId;
      } else {
        return 1;
      }
    } catch (e) {
      print('Error getting selected anak id: $e');
      return 1;
    }
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
      appBar: AppBar(
        backgroundColor: Colors.purple.shade700,
        elevation: 0,
        title: Text(
          'Imunisasi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              _showInfoDialog(context);
            },
          ),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator()) 
        : _error != null 
          ? _buildErrorWidget() 
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeaderSection(screenSize),
                      _buildImunisasiTypeSection(screenSize),
                      _imunisasiController.imunisasiList.isEmpty
                        ? Container(
                            height: 200,
                            child: Center(child: Text('Tidak ada data imunisasi')),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.all(16),
                            itemCount: _imunisasiController.imunisasiList.length,
                            itemBuilder: (context, index) {
                              return _buildImunisasiItem(_imunisasiController.imunisasiList[index], index);
                            },
                          ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
  
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Text(
            'Terjadi kesalahan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? 'Tidak dapat memuat data imunisasi',
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            child: Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
            ),
          ),
          SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Kembali'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeaderSection(Size screenSize) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.purple.shade700,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riwayat Imunisasi',
            style: TextStyle(
              fontSize: screenSize.width * 0.045,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _anakName.isNotEmpty ? _anakName : 'Pilih Anak',
                  style: TextStyle(
                    fontSize: screenSize.width * 0.04,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              if (_anakAge.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _anakAge,
                    style: TextStyle(
                      fontSize: screenSize.width * 0.03,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusIndicator(
                icon: Icons.check_circle,
                label: 'Selesai',
                count: _imunisasiController.getCountByStatus('Sudah'),
                color: Colors.green,
              ),
              _buildStatusIndicator(
                icon: Icons.event,
                label: 'Dijadwalkan',
                count: _imunisasiController.getCountByStatus('Jadwal'),
                color: Colors.orange,
              ),
              _buildStatusIndicator(
                icon: Icons.schedule,
                label: 'Belum',
                count: _imunisasiController.getCountByStatus('Belum'),
                color: Colors.grey,
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: _imunisasiController.getCountByStatus('Sudah') > 0 ? _imunisasiController.getCountByStatus('Sudah') : 1,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(width: 4),
              Expanded(
                flex: _imunisasiController.getCountByStatus('Jadwal') > 0 ? _imunisasiController.getCountByStatus('Jadwal') : 1,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(width: 4),
              Expanded(
                flex: _imunisasiController.getCountByStatus('Belum') > 0 ? _imunisasiController.getCountByStatus('Belum') : 1,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusIndicator({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
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
          count.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
  
  Widget _buildImunisasiTypeSection(Size screenSize) {
    final Map<String, List<Imunisasi>> groupedImunisasi = {};
    
    if (_imunisasiController.imunisasiList.isNotEmpty) {
      for (var imunisasi in _imunisasiController.imunisasiList) {
        String jenis = imunisasi.jenis;
        if (!groupedImunisasi.containsKey(jenis)) {
          groupedImunisasi[jenis] = [];
        }
        groupedImunisasi[jenis]!.add(imunisasi);
      }
    }
    
    if (groupedImunisasi.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jenis Imunisasi',
              style: TextStyle(
                fontSize: screenSize.width * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            Center(
              child: Text(
                'Tidak ada data imunisasi tersedia',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jenis Imunisasi',
            style: TextStyle(
              fontSize: screenSize.width * 0.045,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: groupedImunisasi.entries.map((entry) {
                final jenis = entry.key;
                final count = entry.value.length;
                final Color color = entry.value.first.color;
                
                return Container(
                  width: screenSize.width * 0.4,
                  margin: EdgeInsets.only(right: 12),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _imunisasiController.toggleJenisExpanded(jenis);
                        });
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.vaccines,
                                    color: color,
                                    size: 20,
                                  ),
                                ),
                                Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              jenis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImunisasiItem(Imunisasi imunisasi, int index) {
    Color statusColor;
    IconData statusIcon;
    
    // Check if status contains 'Selesai' or 'Sudah'
    bool isCompleted = imunisasi.status.toLowerCase().contains('selesai') ||
                        imunisasi.status.toLowerCase().contains('sudah');
    
    if (isCompleted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (imunisasi.status == 'Jadwal') {
      statusColor = Colors.orange;
      statusIcon = Icons.event;
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.schedule;
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
              ),
              if (index < _imunisasiController.imunisasiList.length - 1)
                Container(
                  width: 2,
                  height: 80,
                  color: Colors.grey.shade300,
                ),
            ],
          ),
          SizedBox(width: 16),
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  InkWell(
                    onTap: () {
                      _showImunisasiDetail(context, imunisasi);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: imunisasi.color,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      imunisasi.jenis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _formatUsiaRange(imunisasi.minUmurHari, imunisasi.maxUmurHari),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    imunisasi.tanggal.length >= 10 ? imunisasi.tanggal.substring(0, 10) : imunisasi.tanggal,
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Posyandu Mahoni 54',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    statusIcon,
                                    size: 18,
                                    color: statusColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    imunisasi.status,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showImunisasiDetail(BuildContext context, Imunisasi imunisasi) {
    Color statusColor;
    IconData statusIcon;
    
    // Check if status contains 'Selesai' or 'Sudah'
    bool isCompleted = imunisasi.status.toLowerCase().contains('selesai') ||
                        imunisasi.status.toLowerCase().contains('sudah');
    
    if (isCompleted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (imunisasi.status == 'Jadwal') {
      statusColor = Colors.orange;
      statusIcon = Icons.event;
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.schedule;
    }

    // Format tanggal hanya yyyy-mm-dd
    String formattedTanggal = imunisasi.tanggal;
    if (formattedTanggal.length >= 10) {
      formattedTanggal = formattedTanggal.substring(0, 10);
    }

    // Get description and benefits based on immunization type
    String getDescription(String jenis) {
      switch (jenis.toLowerCase()) {
        case 'bcg':
          return 'Vaksin BCG (Bacillus Calmette-Guerin) adalah vaksin untuk mencegah penyakit tuberkulosis (TBC). Vaksin ini diberikan pada bayi baru lahir hingga usia 2 bulan.';
        case 'hepatitis b':
          return 'Vaksin Hepatitis B adalah vaksin untuk mencegah infeksi virus hepatitis B yang dapat menyebabkan kerusakan hati. Vaksin ini diberikan dalam 24 jam pertama setelah lahir.';
        case 'polio':
          return 'Vaksin Polio adalah vaksin untuk mencegah penyakit polio yang dapat menyebabkan kelumpuhan. Vaksin ini diberikan dalam bentuk tetes mulut (OPV) atau suntikan (IPV).';
        case 'dpt':
          return 'Vaksin DPT adalah vaksin kombinasi untuk mencegah tiga penyakit: Difteri, Pertusis (Batuk Rejan), dan Tetanus. Vaksin ini diberikan pada usia 2, 3, dan 4 bulan.';
        case 'campak':
          return 'Vaksin Campak adalah vaksin untuk mencegah penyakit campak yang dapat menyebabkan komplikasi serius. Vaksin ini diberikan pada usia 9 bulan.';
        case 'hib':
          return 'Vaksin Hib adalah vaksin untuk mencegah infeksi Haemophilus influenzae tipe b yang dapat menyebabkan meningitis dan pneumonia.';
        case 'pcv':
          return 'Vaksin PCV (Pneumococcal Conjugate Vaccine) adalah vaksin untuk mencegah infeksi pneumokokus yang dapat menyebabkan pneumonia dan meningitis.';
        case 'rotavirus':
          return 'Vaksin Rotavirus adalah vaksin untuk mencegah infeksi rotavirus yang dapat menyebabkan diare parah pada bayi dan anak-anak.';
        default:
          return 'Imunisasi ini penting untuk melindungi anak dari berbagai penyakit berbahaya.';
      }
    }

    String getBenefits(String jenis) {
      switch (jenis.toLowerCase()) {
        case 'bcg':
          return '• Mencegah TBC pada anak\n• Mengurangi risiko komplikasi TBC\n• Melindungi dari infeksi TBC berat';
        case 'hepatitis b':
          return '• Mencegah infeksi hepatitis B\n• Mencegah kerusakan hati\n• Mengurangi risiko kanker hati';
        case 'polio':
          return '• Mencegah penyakit polio\n• Mencegah kelumpuhan\n• Melindungi dari komplikasi polio';
        case 'dpt':
          return '• Mencegah difteri, pertusis, dan tetanus\n• Mengurangi risiko komplikasi serius\n• Melindungi sistem pernapasan';
        case 'campak':
          return '• Mencegah penyakit campak\n• Mengurangi risiko komplikasi campak\n• Melindungi dari infeksi campak berat';
        case 'hib':
          return '• Mencegah meningitis\n• Mencegah pneumonia\n• Mengurangi risiko infeksi Hib';
        case 'pcv':
          return '• Mencegah pneumonia\n• Mencegah meningitis\n• Mengurangi risiko infeksi pneumokokus';
        case 'rotavirus':
          return '• Mencegah diare parah\n• Mengurangi risiko dehidrasi\n• Melindungi sistem pencernaan';
        default:
          return '• Melindungi dari penyakit berbahaya\n• Meningkatkan sistem kekebalan tubuh\n• Mencegah komplikasi serius';
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: imunisasi.color,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.vaccines,
                    color: Colors.white,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          imunisasi.jenis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatUsiaRange(imunisasi.minUmurHari, imunisasi.maxUmurHari),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Tanggal', formattedTanggal),
                  SizedBox(height: 8),
                  _detailRow('Lokasi', 'Posyandu Mahoni 54'),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Status: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Icon(statusIcon, color: statusColor, size: 16),
                      SizedBox(width: 4),
                      Text(
                        imunisasi.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Deskripsi:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    getDescription(imunisasi.jenis),
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Manfaat:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    getBenefits(imunisasi.jenis),
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
          if (imunisasi.status == 'Jadwal' && imunisasi.id != null)
            ElevatedButton.icon(
              icon: Icon(Icons.check_circle_outline, size: 18),
              label: Text('Tandai Sudah'),
              style: ElevatedButton.styleFrom(
                backgroundColor: imunisasi.color,
              ),
              onPressed: () async {
                final navigator = Navigator.of(context);
                navigator.pop();  // Close the dialog first
                // Show a loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: CircularProgressIndicator(),
                  ),
                );
                try {
                  await _imunisasiController.updateImunisasiStatus(
                    imunisasi.id!,
                    'sudah_sesuai_jadwal'
                  );
                  // Close loading indicator
                  navigator.pop();
                  // Reload data
                  await _loadData();
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Status imunisasi berhasil diubah menjadi "Sudah"',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  // Close loading indicator
                  navigator.pop();
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text('Gagal mengubah status: $e'),
                          ),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
        ],
      ),
    );
  }
  
  Widget _detailRow(String label, String value, {bool isColored = false, Color? color}) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isColored ? color : Colors.grey[700],
            fontWeight: isColored ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
  
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info,
              color: Colors.purple.shade700,
            ),
            SizedBox(width: 8),
            Text('Tentang Imunisasi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Imunisasi sangat penting untuk:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            _bulletPoint('Mencegah penyakit menular yang berbahaya'),
            _bulletPoint('Membangun kekebalan tubuh anak'),
            _bulletPoint('Melindungi anak dari komplikasi serius'),
            _bulletPoint('Mencegah penyebaran penyakit di masyarakat'),
            SizedBox(height: 12),
            Text(
              'Jadwal Imunisasi Dasar Lengkap:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            _bulletPoint('HB-0: diberikan dalam waktu 12 jam setelah lahir'),
            _bulletPoint('BCG & Polio 1: diberikan pada usia 1 bulan'),
            _bulletPoint('DPT-HB-HIP 1 & Polio 2: diberikan pada usia 2 bulan'),
            _bulletPoint('DPT-HB-HIP 2 & Polio 3: diberikan pada usia 3 bulan'),
            _bulletPoint('DPT-HB-HIP 3 & Polio 4: diberikan pada usia 4 bulan'),
            _bulletPoint('Campak: diberikan pada usia 9 bulan'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }
  
  Widget _bulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void updateSelectedChild(int anakId, {String? nama}) {
    setState(() {
      _selectedAnakId = anakId;
      
      if (nama != null && nama.isNotEmpty) {
        _anakName = nama;
      }
    });
    
    _loadData();
  }

  String _formatUsiaRange(int? minHari, int? maxHari) {
    if (minHari == null && maxHari == null) return '';
    if (minHari == null) return 'Usia maksimal $maxHari hari';
    if (maxHari == null) return 'Usia minimal $minHari hari';
    if (minHari == maxHari) {
      if (minHari < 30) {
        return 'Usia $minHari hari';
      } else if (minHari % 30 == 0) {
        return 'Usia ${minHari ~/ 30} bulan';
      } else {
        final bulan = minHari ~/ 30;
        final hari = minHari % 30;
        return 'Usia $bulan bulan $hari hari';
      }
    } else {
      // Range
      if (maxHari < 30) {
        return 'Usia $minHari-$maxHari hari';
      } else if (minHari % 30 == 0 && maxHari % 30 == 0) {
        return 'Usia ${minHari ~/ 30}-${maxHari ~/ 30} bulan';
      } else {
        final minBulan = minHari ~/ 30;
        final minSisaHari = minHari % 30;
        final maxBulan = maxHari ~/ 30;
        final maxSisaHari = maxHari % 30;
        String minStr = minBulan > 0 ? '$minBulan bulan' : '';
        if (minSisaHari > 0) minStr += (minStr.isNotEmpty ? ' ' : '') + '$minSisaHari hari';
        String maxStr = maxBulan > 0 ? '$maxBulan bulan' : '';
        if (maxSisaHari > 0) maxStr += (maxStr.isNotEmpty ? ' ' : '') + '$maxSisaHari hari';
        return 'Usia $minStr - $maxStr';
      }
    }
  }
}
