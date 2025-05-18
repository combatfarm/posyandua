import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../models/perkembangan_model.dart';
import '../../controllers/perkembangan_controller.dart';
import '../../services/perkembangan_service.dart';
import '../../services/anak_service.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

// Pindahkan GrowthData ke level teratas
class GrowthData {
  final int month;
  final double height;
  final double weight;
  final DateTime? tanggal;

  GrowthData({
    required this.month,
    required this.height,
    required this.weight,
    this.tanggal,
  });
}

class PerkembanganScreen extends StatefulWidget {
  final int anakId;

  const PerkembanganScreen({Key? key, required this.anakId}) : super(key: key);

  @override
  _PerkembanganScreenState createState() => _PerkembanganScreenState();
}

class _PerkembanganScreenState extends State<PerkembanganScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late PerkembanganController _perkembanganController;
  final PerkembanganService _perkembanganService = PerkembanganService();
  final AnakService _anakService = AnakService();
  
  bool _isLoading = true;
  String _anakName = '';
  String _anakAge = '';
  List<GrowthData> _growthData = [];
  Map<String, dynamic> _growthStats = {};
  
  // Untuk slider pemilihan anak
  List<dynamic> _anakList = [];
  int _currentAnakIndex = 0;
  int _currentAnakId = 0;
  
  @override
  void initState() {
    super.initState();
    _perkembanganController = PerkembanganController();
    _currentAnakId = widget.anakId;
    
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
    
    _loadAnakList();
    _animationController.forward();
  }

  Future<void> _loadAnakList() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Load daftar anak
      final anakList = await _anakService.getAnakList();
      
      if (!mounted) return;
      
      if (anakList.isNotEmpty) {
        // Cari index anak yang sesuai dengan anakId yang diberikan
        int indexFound = anakList.indexWhere((anak) => anak['id'] == widget.anakId);
        
        setState(() {
          _anakList = anakList;
          _currentAnakIndex = indexFound >= 0 ? indexFound : 0;
          _currentAnakId = anakList[_currentAnakIndex]['id'];
        });
        
        // Load data perkembangan untuk anak yang dipilih
        await _loadData();
      } else {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak ada data anak'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error loading anak list: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat daftar anak: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get child details
      final anakDetail = await _anakService.getAnakDetail(_currentAnakId);
      final namaAnak = anakDetail['nama_anak'] ?? 'Anak';
      
      // Convert tanggal_lahir to usia in months
      final tanggalLahir = DateTime.parse(anakDetail['tanggal_lahir']);
      final now = DateTime.now();
      final ageInDays = now.difference(tanggalLahir).inDays;
      final ageInMonths = (ageInDays / 30).floor(); // Approximate

      // Get growth data from API
      print('Mengambil seluruh riwayat pertumbuhan anak ID: $_currentAnakId');
      final perkembanganList = await _perkembanganService.getPerkembanganByAnakId(_currentAnakId);
      
      // Convert API data to GrowthData model
      final List<GrowthData> apiGrowthData = [];
      
      if (perkembanganList.isNotEmpty) {
        print('Memproses ${perkembanganList.length} data riwayat perkembangan');
        
        for (var item in perkembanganList) {
          try {
            print('Processing item: $item');
            
            // Ensure the data is valid
            if (item['tanggal'] == null || 
                item['tinggi_badan'] == null || 
                item['berat_badan'] == null) {
              print('Skipping item with null values: $item');
              continue;
            }
            
            final tanggal = DateTime.parse(item['tanggal']);
            // Hitung bulan sejak lahir untuk setiap pengukuran
            final monthDiff = ((tanggal.year - tanggalLahir.year) * 12) + 
                             (tanggal.month - tanggalLahir.month);
            
            // Convert string values to double
            double height, weight;
            try {
              height = double.parse(item['tinggi_badan'].toString());
              weight = double.parse(item['berat_badan'].toString());
            } catch (e) {
              print('Error parsing height/weight: $e');
              continue;
            }
            
            apiGrowthData.add(GrowthData(
              month: monthDiff,
              height: height,
              weight: weight,
              tanggal: tanggal, // Tambahkan tanggal untuk referensi
            ));
            
            print('⭐ Menambahkan data pertumbuhan - Tanggal: ${tanggal.toString()}, Bulan ke-$monthDiff: TB=$height cm, BB=$weight kg');
          } catch (e) {
            print('Error processing item: $e');
          }
        }

        // Sort data berdasarkan bulan untuk memastikan grafik berurutan
        apiGrowthData.sort((a, b) => a.month.compareTo(b.month));
        
        // Log data untuk verifikasi
        print('\nData pertumbuhan yang akan ditampilkan dalam grafik:');
        for (var data in apiGrowthData) {
          print('Bulan ke-${data.month}: TB=${data.height} cm, BB=${data.weight} kg (Tanggal: ${data.tanggal})');
        }
      }
      
      // Calculate statistics menggunakan data terbaru
      Map<String, dynamic> stats = {};
      if (apiGrowthData.isNotEmpty) {
        // Ambil data terbaru (bukan data dengan bulan tertinggi, tapi data dengan tanggal terbaru)
        final latest = apiGrowthData.reduce((a, b) => 
          (a.tanggal?.isAfter(b.tanggal ?? DateTime(1900)) ?? false) ? a : b);
        
        print('🔍 Menggunakan data terbaru (tanggal: ${latest.tanggal}) untuk status pertumbuhan saat ini');
        
        // Get status from service
        final statusPertumbuhan = _perkembanganService.hitungStatusPertumbuhan(
          latest.weight, 
          latest.height, 
          ageInMonths,
          anakDetail['jenis_kelamin'] ?? 'Laki-laki',
        );
        
        stats = {
          'height': {
            'value': latest.height,
            'percentile': '75%', // Placeholder
            'stdDev': '+1.2',    // Placeholder
            'status': statusPertumbuhan['status_tb'],
          },
          'weight': {
            'value': latest.weight,
            'percentile': '60%', // Placeholder
            'stdDev': '+0.8',    // Placeholder
            'status': statusPertumbuhan['status_bb'],
          },
        };
      }

      if (mounted) {
        setState(() {
          _anakName = namaAnak;
          _anakAge = '$ageInMonths bulan';
          _growthData = apiGrowthData;
          _growthStats = stats;
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print('Error loading data: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _growthData = []; // Kosongkan data jika error
          _growthStats = {};
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _changeSelectedAnak(int direction) {
    if (_anakList.isEmpty) return;
    
    setState(() {
      // Hitung index anak baru (dengan wrapping)
      _currentAnakIndex = (_currentAnakIndex + direction) % _anakList.length;
      if (_currentAnakIndex < 0) _currentAnakIndex = _anakList.length - 1;
      
      // Update current anak ID
      _currentAnakId = _anakList[_currentAnakIndex]['id'];
      
      // Tandai bahwa loading dimulai
      _isLoading = true;
    });
    
    // Tunggu state selesai diperbarui sebelum memuat data
    Future.microtask(() {
      // Load data untuk anak yang baru dipilih
      _loadData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Metode khusus untuk refresh yang dipanggil oleh RefreshIndicator
  Future<void> _handleRefresh() async {
    print('🔄 Pull-to-refresh: Starting refresh...');
    
    // Reset loading state tetapi jangan tampilkan loading spinner penuh
    // agar RefreshIndicator masih terlihat
    
    try {
      // Bersihkan cache API terkait perkembangan terlebih dahulu
      // untuk memastikan mengambil data terbaru dari server
      final ApiService apiService = ApiService();
      print('🧹 Membersihkan cache perkembangan untuk memastikan data terbaru...');
      
      // Hapus cache khusus perkembangan
      apiService.clearCache(); // Ini akan membersihkan semua cache termasuk perkembangan
      
      // Refresh data anak
      await _loadData();
      
      print('✅ Pull-to-refresh: Data successfully refreshed');
      
      // Berikan feedback ke user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Data terbaru berhasil dimuat',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Pull-to-refresh: Error during refresh: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gagal memuat data terbaru: $e',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    
    print('🔄 Pull-to-refresh: Completed');
    return;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        title: Text(
          'Perkembangan Anak',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: Colors.blue.shade700))
        : FadeTransition(
        opacity: _fadeAnimation,
            child: RefreshIndicator(
              color: Colors.blue.shade700,
              onRefresh: _handleRefresh,
              key: PageStorageKey('refresh_graph'),
              child: _buildGrowthGraphs(screenSize),
            ),
      ),
    );
  }

  Widget _buildGrowthGraphs(Size screenSize) {
    // Pastikan konten scrollable bahkan jika kosong
    return SingleChildScrollView(
      key: PageStorageKey('growth_graphs_scroll'),
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 200, // Estimasi tinggi tab minus app bar
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Pertumbuhan',
            style: TextStyle(
              fontSize: screenSize.width * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
            SizedBox(height: 8),
            
            // Selector anak
            _buildAnakSelector(),
            
          SizedBox(height: 8),
          Text(
              '$_anakName - $_anakAge',
            style: TextStyle(
              fontSize: screenSize.width * 0.035,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          
            if (_growthData.isEmpty)
              _buildEmptyStateCard()
            else
              Column(
                children: [
          // Height card
                _buildGrowthCard(
                  title: 'Tinggi Badan',
                  value: '${_growthStats['height']?['value'] ?? 0} cm',
                  icon: Icons.height,
                  color: Colors.blue,
                  dataKey: 'height',
                  maxY: 120,
                  minY: 45,
                  stats: _growthStats['height'] ?? {},
                ),
                SizedBox(height: 20),
                
                // Weight card
                _buildGrowthCard(
                  title: 'Berat Badan',
                  value: '${_growthStats['weight']?['value'] ?? 0} kg',
                  icon: Icons.monitor_weight,
                  color: Colors.orange,
                  dataKey: 'weight',
                  maxY: 25,
                  minY: 2,
                  stats: _growthStats['weight'] ?? {},
                ),
              ],
            ),
            
            // Tambahkan padding di bawah konten untuk pengalaman scroll yang lebih baik
            SizedBox(height: 50),
          ],
                          ),
      ),
    );
  }
  
  Widget _buildAnakSelector() {
    if (_anakList.isEmpty) return SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
                      ),
                    ],
                  ),
      child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, size: 18, color: Colors.blue.shade700),
            onPressed: () => _changeSelectedAnak(-1),
          ),
          Expanded(
            child: Column(
                        children: [
                          Text(
                  'Pilih Anak',
                            style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                            ),
                          ),
                SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    for (int i = 0; i < _anakList.length; i++)
                      Container(
                        width: 8,
                        height: 8,
                        margin: EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _currentAnakIndex 
                              ? Colors.blue.shade700 
                              : Colors.grey.shade300,
                        ),
                      ),
                  ],
                      ),
                    ],
                  ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.blue.shade700),
            onPressed: () => _changeSelectedAnak(1),
                  ),
                ],
              ),
    );
  }
  
  Widget _buildEmptyStateCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
                    ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
                    children: [
            Icon(
              Icons.bar_chart,
              size: 60,
              color: Colors.grey.shade400,
          ),
            SizedBox(height: 16),
            Text(
              'Belum ada data pertumbuhan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
                      ),
            ),
            SizedBox(height: 8),
            Text(
              'Tidak ada data pertumbuhan untuk ditampilkan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
                      ),
                    ],
                  ),
              ),
    );
  }
  
  Widget _buildGrowthCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String dataKey,
    required double maxY,
    required double minY,
    required Map<String, dynamic> stats,
  }) {
    return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                    Icon(icon, color: color),
                          SizedBox(width: 8),
                          Text(
                      title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                  value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                    color: color,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Keterangan tentang grafik
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Grafik menampilkan seluruh riwayat pengukuran untuk melihat perkembangan dari waktu ke waktu',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 200,
                    child: CustomPaint(
                      size: Size(double.infinity, 200),
                      painter: GraphPainter(
                  data: _growthData,
                  dataKey: dataKey,
                  maxY: maxY,
                  minY: minY,
                  lineColor: color,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildGrowthStat(
                        title: 'Persentil', 
                  value: stats['percentile'] ?? '-', 
                  color: color,
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      _buildGrowthStat(
                        title: 'Std. Deviasi', 
                  value: stats['stdDev'] ?? '-', 
                  color: color,
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      _buildGrowthStat(
                        title: 'Status', 
                  value: stats['status'] ?? 'Normal', 
                  color: _getStatusColor(stats['status']),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
  
  Color _getStatusColor(String? status) {
    if (status == null) return Colors.green;
    
    switch (status.toLowerCase()) {
      case 'kurang':
      case 'pendek':
        return Colors.orange;
      case 'lebih':
      case 'tinggi':
        return Colors.blue;
      case 'normal':
      default:
        return Colors.green;
    }
  }
  
  Widget _buildGrowthStat({
    required String title, 
    required String value, 
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Pindahkan GraphPainter ke level teratas
class GraphPainter extends CustomPainter {
  final List<GrowthData> data;
  final String dataKey;
  final double maxY;
  final double minY;
  final Color lineColor;

  GraphPainter({
    required this.data,
    required this.dataKey,
    required this.maxY,
    required this.minY,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Skip drawing if we don't have enough data
    if (data.isEmpty) {
      return;
    }

    // Draw axes
    final Paint axesPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
      
    // X axis
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      axesPaint,
    );
    
    // Y axis
    canvas.drawLine(
      Offset(0, 0),
      Offset(0, size.height),
      axesPaint,
    );
    
    // Draw grid lines
    for (int i = 0; i < 5; i++) {
      final y = size.height - (i * size.height / 4);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        axesPaint,
      );
      
      // Draw y-axis labels
      final value = minY + (i * (maxY - minY) / 4);
      final textSpan = TextSpan(
        text: value.toStringAsFixed(1),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 10,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(-25, y - 6));
    }
    
    // Calculate x step - handle case when there's only one data point
    final xStep = data.length > 1 
        ? size.width / (data.length - 1)
        : size.width;
    
    // Draw vertical grid lines and x-axis labels
    for (int i = 0; i < data.length; i++) {
      final x = data.length > 1 ? i * xStep : size.width / 2;
      
      // Vertical grid line
      if (i > 0 && i < data.length - 1) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          axesPaint,
        );
      }
      
      // X-axis label
      String label;
      if (data[i].tanggal != null) {
        label = DateFormat('dd/MM').format(data[i].tanggal!);
      } else {
        label = '${data[i].month}';
      }
      
      final textSpan = TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 10,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 10, size.height + 5));
    }
    
    // Only draw line chart if we have data
    if (data.isEmpty) {
      return;
    }
    
    // Draw line chart
    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
      
    final Paint fillPaint = Paint()
      ..color = lineColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;
      
    final Path linePath = Path();
    final Path fillPath = Path();
    
    // For single point, draw a dot instead of a line
    if (data.length == 1) {
      final rawY = dataKey == 'height' ? data[0].height : data[0].weight;
      final normalizedY = (rawY - minY) / (maxY - minY);
      final y = size.height - (normalizedY * size.height);
      final x = size.width / 2;
      
      // Draw point
      final Paint pointPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.fill;
        
      final Paint pointStrokePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      
      // Add to fill path for the background
      fillPath.moveTo(x, size.height);
      fillPath.lineTo(x, y);
      fillPath.lineTo(x, size.height);
      fillPath.close();
      
      canvas.drawCircle(Offset(x, y), 5, pointPaint);
      canvas.drawCircle(Offset(x, y), 5, pointStrokePaint);
      canvas.drawPath(fillPath, fillPaint);
      return;
    }
    
    // Multiple points - draw a line
    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      final rawY = dataKey == 'height' ? data[i].height : data[i].weight;
      
      // Ensure valid bounds to prevent NaN values
      final normalizedY = (maxY > minY) 
          ? ((rawY - minY) / (maxY - minY)).clamp(0.0, 1.0)
          : 0.5; // Default to middle if min=max
          
      final y = size.height - (normalizedY * size.height);
      
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      
      // Draw point
      final Paint pointPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.fill;
        
      final Paint pointStrokePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
        
      canvas.drawCircle(Offset(x, y), 5, pointPaint);
      canvas.drawCircle(Offset(x, y), 5, pointStrokePaint);
    }
    
    // Complete fill path
    fillPath.lineTo((data.length - 1) * xStep, size.height);
    fillPath.close();
    
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
