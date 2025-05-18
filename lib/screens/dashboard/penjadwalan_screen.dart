import 'package:flutter/material.dart';
import 'package:posyandu/models/jadwal_model.dart';
import 'package:posyandu/services/jadwal_service.dart';
import 'package:intl/intl.dart';

class PenjadwalanScreen extends StatefulWidget {
  final int anakId;
  
  const PenjadwalanScreen({Key? key, required this.anakId}) : super(key: key);

  @override
  _PenjadwalanScreenState createState() => _PenjadwalanScreenState();
}

class _PenjadwalanScreenState extends State<PenjadwalanScreen> with SingleTickerProviderStateMixin {
  final JadwalService _jadwalService = JadwalService();
  List<JadwalModel> _jadwalList = [];
  bool _isLoading = true;
  String _selectedFilter = 'semua';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  JadwalModel? _nextJadwal;
  bool _isLoadingNextJadwal = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _loadJadwal();
    _loadNextJadwal();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadJadwal() async {
    setState(() => _isLoading = true);
    try {
      final jadwal = await _jadwalService.getRiwayatJadwalAnak(widget.anakId);
      setState(() {
        _jadwalList = jadwal;
        _isLoading = false;
      });
      _fadeController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadNextJadwal() async {
    setState(() { _isLoadingNextJadwal = true; });
    try {
      final nearest = await _jadwalService.getNearestJadwalForChild(widget.anakId);
      setState(() {
        _nextJadwal = nearest;
        _isLoadingNextJadwal = false;
      });
    } catch (e) {
      setState(() {
        _nextJadwal = null;
        _isLoadingNextJadwal = false;
      });
    }
  }

  List<JadwalModel> _getFilteredJadwal() {
    if (_selectedFilter == 'semua') {
      return _jadwalList;
    }
    return _jadwalList.where((jadwal) => jadwal.jenis == _selectedFilter).toList();
  }

  String _getStatusText(JadwalModel jadwal) {
    if (jadwal.status != null && jadwal.status!.isNotEmpty) {
      final statusLower = jadwal.status!.toLowerCase();
      if (statusLower.contains('selesai') || statusLower.contains('sudah')) {
        return 'Selesai';
      } else if (statusLower.contains('batal')) {
        return 'Dibatalkan';
      } else {
        return 'Belum Dilaksanakan';
      }
    }
    if (jadwal.isImplemented == true) {
      return 'Sudah Dilaksanakan';
    } else {
      return 'Belum Dilaksanakan';
    }
  }

  Color _getStatusColor(JadwalModel jadwal) {
    if (jadwal.status != null && jadwal.status!.isNotEmpty) {
      final statusLower = jadwal.status!.toLowerCase();
      if (statusLower.contains('selesai') || statusLower.contains('sudah')) {
        return Colors.green.shade600;
      } else if (statusLower.contains('batal')) {
        return Colors.red.shade400;
      } else {
        return Colors.orange.shade400;
      }
    }
    if (jadwal.isImplemented == true) {
      return Colors.green.shade600;
    } else {
      return Colors.orange.shade400;
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
        return Colors.purple.shade50;
      case 'vitamin':
        return Colors.orange.shade50;
      case 'pemeriksaan rutin':
        return Colors.blue.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  LinearGradient _getJenisGradient(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'imunisasi':
        return LinearGradient(colors: [Colors.purple.shade100, Colors.teal.shade50]);
      case 'vitamin':
        return LinearGradient(colors: [Colors.orange.shade100, Colors.teal.shade50]);
      case 'pemeriksaan rutin':
        return LinearGradient(colors: [Colors.blue.shade100, Colors.teal.shade50]);
      default:
        return LinearGradient(colors: [Colors.grey.shade100, Colors.teal.shade50]);
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

  void _showJadwalDetail(JadwalModel jadwal) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(_getJenisIcon(jadwal.jenis), color: Colors.teal.shade700, size: 44),
              ),
              SizedBox(height: 16),
              Text(jadwal.nama, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.teal.shade900)),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(jadwal.jenis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
              ),
              SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 18, color: Colors.teal.shade400),
                  SizedBox(width: 6),
                  Text(DateFormat('dd MMMM yyyy').format(jadwal.tanggal), style: TextStyle(fontSize: 15, color: Colors.teal.shade800)),
                ],
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.teal.shade400),
                  SizedBox(width: 4),
                  Text('Waktu:', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.teal.shade800, fontFamily: 'Roboto')),
                  SizedBox(width: 4),
                  Text(jadwal.waktu ?? '-', style: TextStyle(fontSize: 15, color: Colors.teal.shade800, fontFamily: 'Roboto')),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.teal.shade400),
                  SizedBox(width: 4),
                  Text('Posyandu Mahoni 54', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.teal.shade800, fontFamily: 'Roboto')),
                ],
              ),
              if (jadwal.keterangan != null && jadwal.keterangan!.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(jadwal.keterangan!, style: TextStyle(color: Colors.teal.shade900, fontSize: 15), textAlign: TextAlign.center),
              ],
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(jadwal).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_getStatusText(jadwal), style: TextStyle(color: _getStatusColor(jadwal), fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredJadwal = _getFilteredJadwal();
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        title: Text('Jadwal Anak', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          PopupMenuButton<String>(
            color: Colors.white,
            onSelected: (String value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'semua',
                child: Text('Semua Jadwal', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
              PopupMenuItem(
                value: 'pemeriksaan rutin',
                child: Text('Pemeriksaan Rutin', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
              PopupMenuItem(
                value: 'imunisasi',
                child: Text('Imunisasi', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
              PopupMenuItem(
                value: 'vitamin',
                child: Text('Vitamin', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadJadwal();
          await _loadNextJadwal();
        },
        color: Colors.teal.shade700,
        child: Column(
          children: [
            // Jadwal terdekat
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: _isLoadingNextJadwal
                  ? Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _nextJadwal == null
                      ? Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.07),
                                blurRadius: 16,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text('Tidak ada jadwal terdekat', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        )
                      : Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(24),
                          margin: EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withOpacity(0.10),
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.teal.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(_getJenisIcon(_nextJadwal!.jenis ?? '-'), color: _getJenisSolidColor(_nextJadwal!.jenis ?? '-'), size: 40),
                              ),
                              SizedBox(width: 22),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.shade200,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text('Jadwal Terdekat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(_nextJadwal!.nama ?? '-', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.teal.shade900)),
                                    SizedBox(height: 4),
                                    Text(_nextJadwal!.jenis ?? '-', style: TextStyle(fontSize: 14, color: Colors.teal.shade700)),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 16, color: Colors.teal.shade400),
                                        SizedBox(width: 4),
                                        Text(_nextJadwal!.tanggal != null ? DateFormat('dd MMM yyyy').format(_nextJadwal!.tanggal) : '-', style: TextStyle(fontSize: 15, color: Colors.teal.shade800)),
                                        SizedBox(width: 12),
                                        Icon(Icons.access_time, size: 16, color: Colors.teal.shade400),
                                        SizedBox(width: 4),
                                        Text(_nextJadwal!.waktu ?? '-', style: TextStyle(fontSize: 15, color: Colors.teal.shade800)),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 16, color: Colors.teal.shade400),
                                        SizedBox(width: 4),
                                        Text('Posyandu Mahoni 54', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.teal.shade800)),
                                      ],
                                    ),
                                    if (_nextJadwal!.keterangan != null && _nextJadwal!.keterangan!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(_nextJadwal!.keterangan!, style: TextStyle(color: Colors.teal.shade900, fontSize: 14)),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
            // Header dengan ilustrasi
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: 32, left: 24, right: 24, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.teal.shade700,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month, color: Colors.white, size: 36),
                      SizedBox(width: 12),
                      Text('Jadwal Anak', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('Lihat semua jadwal imunisasi, vitamin, dan pemeriksaan anak Anda.',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15)),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : filteredJadwal.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy, size: 100, color: Colors.teal.shade100),
                              SizedBox(height: 20),
                              Text('Belum ada jadwal', style: TextStyle(fontSize: 22, color: Colors.teal.shade700, fontWeight: FontWeight.bold, fontFamily: 'Roboto')),
                              SizedBox(height: 10),
                              Text('Jadwal imunisasi, vitamin, atau pemeriksaan akan muncul di sini.',
                                style: TextStyle(color: Colors.teal.shade600, fontSize: 16, fontFamily: 'Roboto'), textAlign: TextAlign.center),
                            ],
                          ),
                        )
                      : FadeTransition(
                          opacity: _fadeAnimation,
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            itemCount: filteredJadwal.length,
                            itemBuilder: (context, index) {
                              final jadwal = filteredJadwal[index];
                              return AnimatedScale(
                                scale: 1,
                                duration: Duration(milliseconds: 400 + index * 60),
                                curve: Curves.easeOutBack,
                                child: GestureDetector(
                                  onTap: () => _showJadwalDetail(jadwal),
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 18),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: _getJenisSolidColor(jadwal.jenis),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _getJenisSolidColor(jadwal.jenis).withOpacity(0.10),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Leading icon
                                          Container(
                                            padding: EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: _getJenisSolidColor(jadwal.jenis).withOpacity(0.13),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(_getJenisIcon(jadwal.jenis), color: _getJenisSolidColor(jadwal.jenis), size: 28),
                                          ),
                                          SizedBox(width: 16),
                                          // Expanded content
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(jadwal.nama, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal.shade900, fontFamily: 'Roboto')),
                                                    ),
                                                    Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: _getJenisSolidColor(jadwal.jenis).withOpacity(0.13),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Text(
                                                        jadwal.jenis,
                                                        style: TextStyle(
                                                          color: _getJenisSolidColor(jadwal.jenis),
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                          fontFamily: 'Roboto',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(Icons.calendar_today, size: 14, color: Colors.teal.shade400),
                                                    SizedBox(width: 4),
                                                    Text(DateFormat('dd MMMM yyyy').format(jadwal.tanggal), style: TextStyle(fontSize: 13, color: Colors.teal.shade800, fontFamily: 'Roboto')),
                                                  ],
                                                ),
                                                SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(Icons.access_time, size: 14, color: Colors.teal.shade400),
                                                    SizedBox(width: 4),
                                                    Text('Waktu:', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.teal.shade800, fontFamily: 'Roboto')),
                                                    SizedBox(width: 4),
                                                    Text(jadwal.waktu ?? '-', style: TextStyle(fontSize: 13, color: Colors.teal.shade800, fontFamily: 'Roboto')),
                                                  ],
                                                ),
                                                SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(Icons.location_on, size: 14, color: Colors.teal.shade400),
                                                    SizedBox(width: 4),
                                                    Text('Posyandu Mahoni 54', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.teal.shade800, fontFamily: 'Roboto')),
                                                  ],
                                                ),
                                                if (jadwal.keterangan != null && jadwal.keterangan!.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 6.0),
                                                    child: Text(jadwal.keterangan!, style: TextStyle(fontSize: 13, color: Colors.teal.shade900, fontFamily: 'Roboto')),
                                                  ),
                                                SizedBox(height: 10),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: _getStatusColor(jadwal),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Text(
                                                        _getStatusText(jadwal),
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                          fontFamily: 'Roboto',
                                                        ),
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
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
