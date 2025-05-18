import 'package:flutter/material.dart';
import '../../models/vitamin_model.dart';
import '../../controllers/vitamin_controller.dart';
import '../../services/vitamin_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VitaminScreen extends StatefulWidget {
  final int? anakId;
  final String? anakName;
  
  const VitaminScreen({Key? key, this.anakId, this.anakName}) : super(key: key);
  
  @override
  _VitaminScreenState createState() => _VitaminScreenState();
}

class _VitaminScreenState extends State<VitaminScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late VitaminController _vitaminController;
  final VitaminService _vitaminService = VitaminService();
  bool _isLoading = true;
  String? _error;
  int? _selectedAnakId;
  String _anakName = "";
  String _anakAge = "";
  
  final Map<String, bool> jenisExpanded = {};

  @override
  void initState() {
    super.initState();
    _vitaminController = VitaminController();
    
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
        backgroundColor: Colors.orange.shade700,
        elevation: 0,
        title: Text(
          'Vitamin',
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
        ? Center(child: CircularProgressIndicator(color: Colors.orange.shade700)) 
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
                      _buildVitaminTypeSection(screenSize),
                      _vitaminController.vitaminList.isEmpty
                        ? Container(
                            height: 200,
                            child: Center(child: Text('Tidak ada data vitamin')),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.all(16),
                            itemCount: _vitaminController.vitaminList.length,
                            itemBuilder: (context, index) {
                              return _buildVitaminItem(_vitaminController.vitaminList[index], index);
                            },
                          ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
  
  Widget _buildHeaderSection(Size screenSize) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
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
            'Riwayat Vitamin',
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
                count: _vitaminController.getCountByStatus('Sudah'),
                color: Colors.green,
              ),
              _buildStatusIndicator(
                icon: Icons.event,
                label: 'Dijadwalkan',
                count: _vitaminController.getCountByStatus('Jadwal'),
                color: Colors.blue,
              ),
              _buildStatusIndicator(
                icon: Icons.schedule,
                label: 'Belum',
                count: _vitaminController.getCountByStatus('Belum'),
                color: Colors.grey,
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: _vitaminController.getCountByStatus('Sudah') > 0 ? _vitaminController.getCountByStatus('Sudah') : 1,
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
                flex: _vitaminController.getCountByStatus('Jadwal') > 0 ? _vitaminController.getCountByStatus('Jadwal') : 1,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(width: 4),
              Expanded(
                flex: _vitaminController.getCountByStatus('Belum') > 0 ? _vitaminController.getCountByStatus('Belum') : 1,
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
  
  Widget _buildVitaminTypeSection(Size screenSize) {
    // Group vitamins by type
    final Map<String, List<Vitamin>> groupedVitamins = {};
    for (var vitamin in _vitaminController.vitaminList) {
      String jenis = vitamin.jenis;
      if (!groupedVitamins.containsKey(jenis)) {
        groupedVitamins[jenis] = [];
      }
      groupedVitamins[jenis]!.add(vitamin);
    }
    
    if (groupedVitamins.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jenis Vitamin',
              style: TextStyle(
                fontSize: screenSize.width * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
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
            'Jenis Vitamin',
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
              children: groupedVitamins.entries.map((entry) {
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
                          jenisExpanded[jenis] = !(jenisExpanded[jenis] ?? false);
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
                                    Icons.medication,
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
  
  Widget _buildVitaminItem(Vitamin vitamin, int index) {
    Color statusColor;
    IconData statusIcon;
    
    switch (vitamin.status.toLowerCase()) {
      case 'sudah':
      case 'selesai':
      case 'sudah_sesuai_jadwal':
      case 'selesai_sesuai':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'jadwal':
        statusColor = Colors.blue;
        statusIcon = Icons.event;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.schedule;
    }
    // Format tanggal hanya yyyy-mm-dd
    String formattedTanggal = vitamin.tanggal;
    if (formattedTanggal.length >= 10) {
      formattedTanggal = formattedTanggal.substring(0, 10);
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
              if (index < _vitaminController.vitaminList.length - 1)
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
                      _showVitaminDetail(context, vitamin);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: vitamin.color,
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
                                      vitamin.jenis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Usia ${vitamin.usia}',
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
                                    formattedTanggal,
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
                                    vitamin.lokasi,
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
                                    vitamin.status,
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
  
  void _showVitaminDetail(BuildContext context, Vitamin vitamin) {
    Color statusColor;
    IconData statusIcon;
    
    switch (vitamin.status.toLowerCase()) {
      case 'sudah':
      case 'selesai':
      case 'sudah_sesuai_jadwal':
      case 'selesai_sesuai':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'jadwal':
        statusColor = Colors.blue;
        statusIcon = Icons.event;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.schedule;
    }
    // Format tanggal hanya yyyy-mm-dd
    String formattedTanggal = vitamin.tanggal;
    if (formattedTanggal.length >= 10) {
      formattedTanggal = formattedTanggal.substring(0, 10);
    }
    // Get description and benefits based on vitamin type
    String getDescription(String jenis) {
      switch (jenis.toLowerCase()) {
        case 'a biru':
        case 'vitamin a':
          if (vitamin.usia.toLowerCase().contains('6')) {
            return 'Vitamin A biru (100.000 IU) diberikan pada usia 6-11 bulan untuk mencegah kekurangan vitamin A yang dapat menyebabkan gangguan penglihatan dan meningkatkan kerentanan terhadap infeksi.';
          } else if (vitamin.usia.toLowerCase().contains('12') || vitamin.usia.toLowerCase().contains('59')) {
            return 'Vitamin A merah (200.000 IU) diberikan pada usia 12-59 bulan untuk mencegah kekurangan vitamin A yang dapat menyebabkan gangguan penglihatan dan meningkatkan kerentanan terhadap infeksi.';
          }
          return 'Vitamin A adalah suplemen penting untuk kesehatan mata dan sistem kekebalan tubuh anak.';
        case 'vitamin d':
          return 'Vitamin D penting untuk pertumbuhan tulang dan gigi yang kuat serta membantu penyerapan kalsium dan fosfor.';
        case 'vitamin b kompleks':
          return 'Vitamin B Kompleks membantu metabolisme, pertumbuhan, dan perkembangan anak serta pembentukan sel darah merah.';
        case 'vitamin c':
          return 'Vitamin C adalah antioksidan yang membantu meningkatkan sistem kekebalan tubuh dan penyerapan zat besi.';
        case 'zat besi':
          return 'Suplemen zat besi penting untuk mencegah anemia dan membantu pembentukan hemoglobin.';
        default:
          return 'Suplemen ini penting untuk mendukung pertumbuhan dan perkembangan anak.';
      }
    }
    String getBenefits(String jenis) {
      switch (jenis.toLowerCase()) {
        case 'a biru':
        case 'vitamin a':
          return '• Mencegah gangguan penglihatan dan rabun senja\n• Meningkatkan sistem kekebalan tubuh\n• Menjaga kesehatan kulit dan jaringan\n• Mencegah infeksi saluran pernapasan';
        case 'vitamin d':
          return '• Membantu pertumbuhan tulang dan gigi\n• Mencegah rakitis\n• Meningkatkan penyerapan kalsium\n• Mendukung sistem kekebalan tubuh';
        case 'vitamin b kompleks':
          return '• Mendukung pertumbuhan dan perkembangan\n• Membantu pembentukan sel darah merah\n• Meningkatkan fungsi sistem saraf\n• Membantu metabolisme energi';
        case 'vitamin c':
          return '• Meningkatkan sistem kekebalan tubuh\n• Membantu penyerapan zat besi\n• Menjaga kesehatan kulit\n• Mencegah infeksi';
        case 'zat besi':
          return '• Mencegah anemia\n• Meningkatkan konsentrasi dan daya ingat\n• Meningkatkan energi\n• Mendukung pertumbuhan optimal';
        default:
          return '• Mendukung pertumbuhan dan perkembangan\n• Meningkatkan sistem kekebalan tubuh\n• Mencegah defisiensi nutrisi\n• Menjaga kesehatan optimal';
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
                color: vitamin.color,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.medication,
                    color: Colors.white,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vitamin.jenis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Usia ${vitamin.usia}',
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
                  _detailRow('Lokasi', vitamin.lokasi),
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
                        vitamin.status,
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
                    getDescription(vitamin.jenis),
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
                    getBenefits(vitamin.jenis),
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
          if (vitamin.status.toLowerCase() == 'belum' || vitamin.status.toLowerCase() == 'jadwal')
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: vitamin.color,
              ),
              onPressed: () async {
                Navigator.pop(context);
                
                // Show loading indicator
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 16),
                        Text('Memperbarui status vitamin...'),
                      ],
                    ),
                    duration: Duration(seconds: 1),
                  ),
                );
                
                // Update status
                final success = await _vitaminController.updateVitaminStatus(
                  vitamin.id,
                  'Sudah'
                );
                
                if (success) {
                  // Refresh UI after status update
                  setState(() {});
                  
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Status vitamin berhasil diubah'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Gagal mengubah status vitamin'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text('Tandai Sudah'),
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
              color: Colors.orange.shade700,
            ),
            SizedBox(width: 8),
            Text('Tentang Vitamin A'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vitamin A sangat penting untuk:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            _bulletPoint('Kesehatan mata dan penglihatan'),
            _bulletPoint('Meningkatkan imunitas tubuh'),
            _bulletPoint('Pertumbuhan dan perkembangan sel'),
            _bulletPoint('Menjaga kesehatan kulit'),
            SizedBox(height: 12),
            Text(
              'Program pemberian Vitamin A pada anak:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            _bulletPoint('Vitamin A biru (100.000 IU): untuk anak usia 6-11 bulan'),
            _bulletPoint('Vitamin A merah (200.000 IU): untuk anak usia 12-59 bulan'),
            SizedBox(height: 12),
            Text(
              'Kekurangan Vitamin A dapat menyebabkan:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            _bulletPoint('Gangguan penglihatan dan rabun senja'),
            _bulletPoint('Lebih mudah terserang infeksi'),
            _bulletPoint('Gangguan pertumbuhan'),
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
              _error ?? 'Tidak dapat memuat data vitamin',
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            child: Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
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

  // Load vitamin data from API
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
      
      try {
        // Fetch vitamin data for the child
        await _vitaminController.fetchVitaminData(anakId);
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error loading vitamin data: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
            if (e.toString().contains('Data anak tidak ditemukan')) {
              _error = 'Data anak tidak ditemukan. Silakan pilih anak lain di menu Dashboard.';
            } else {
              _error = 'Gagal memuat data vitamin: $e';
            }
          });
        }
      }
    } catch (e) {
      print('Error getting selected anak ID: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Gagal mendapatkan data anak: $e';
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
        // Fetch anak data
        await _vitaminController.fetchAnakData(anakId);
        
        if (_vitaminController.anakData != null) {
          String nama = _vitaminController.anakData!['nama_anak'] ?? '';
          String usia = _vitaminController.getChildAge();
          
          setState(() {
            _anakName = nama.isNotEmpty ? nama : "Anak $anakId";
            _anakAge = usia;
          });
          
          await prefs.setString('anak_name_$anakId', _anakName);
          await prefs.setString('anak_age_$anakId', usia);
          
          print('Saved anak data: $_anakName, $_anakAge');
        }
      } catch (e) {
        print('Error mengambil data anak dari API: $e');
        setState(() {
          _anakName = "Anak $anakId";
          _anakAge = "";
        });
      }
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

  // Add a method to handle updating selected child
  void updateSelectedChild(int anakId, {String? nama}) {
    setState(() {
      _vitaminController.anakId = anakId;
    });
    
    _loadData();
  }
}
