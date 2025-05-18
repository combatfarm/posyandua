import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:posyandu/services/anak_service.dart';
import 'package:posyandu/screens/dashboard/anak_form_screen.dart';
import 'package:posyandu/screens/dashboard/penjadwalan_screen.dart';
import 'package:posyandu/models/anak_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnakScreen extends StatefulWidget {
  @override
  _AnakScreenState createState() => _AnakScreenState();
}

class _AnakScreenState extends State<AnakScreen> {
  final AnakService _anakService = AnakService();
  bool _isLoading = false;
  List<dynamic> _anakList = [];
  Map<String, dynamic> _parentData = {}; // Parent data from SharedPreferences

  @override
  void initState() {
    super.initState();
    _loadParentData();
    _loadAnakData();
  }

  Future<void> _loadParentData() async {
    try {
      final parentData = await _anakService.getParentFromPrefs();
      setState(() {
        _parentData = parentData;
      });
      
      // Tambahkan nama default jika masih kosong
      if (_parentData['nama'] == null || _parentData['nama'].toString().isEmpty) {
        setState(() {
          _parentData['nama'] = 'Ibu';
        });
      }
      
      print('Data parent berhasil dimuat: $_parentData');
    } catch (e) {
      print('Error saat memuat data parent: $e');
      
      // Pastikan masih ada nilai default
      setState(() {
        _parentData = {
          'nama': 'Ibu',
          'nik': 'Tidak tersedia'
        };
      });
    }
  }

  Future<void> _loadAnakData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Memuat data anak...');
      
      // Log parent data yang tersedia
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final nik = prefs.getString('nik');
      final namaIbu = prefs.getString('nama_ibu');
      
      print('Data dari SharedPreferences: user_id=$userId, nik=$nik, nama_ibu=$namaIbu');
      
      // Gunakan AnakService untuk mendapatkan data
      final anakList = await _anakService.getAnakList();
      
      // Reload parent data after API call (might be updated)
      await _loadParentData();
      
      setState(() {
        _anakList = anakList;
        _isLoading = false;
      });
      
      print('Berhasil memuat ${_anakList.length} data anak');
      
      // Periksa apakah API mengembalikan data pengguna
      if (anakList.isNotEmpty) {
        final firstAnak = anakList[0];
        print('Sample anak: ID=${firstAnak['id']}, nama=${firstAnak['nama_anak']}, pengguna_id=${firstAnak['pengguna_id']}');
        
        if (firstAnak['pengguna'] != null) {
          print('Data pengguna dari API: ${firstAnak['pengguna']}');
        } else {
          print('Data pengguna tidak ada dalam respons API, akan menggunakan data lokal');
        }
      }
    } catch (e) {
      print('Error saat memuat data anak: $e');
      setState(() {
        _isLoading = false;
        _anakList = []; // Ensure empty list on error instead of using manual data
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data anak: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAnak(int id) async {
    try {
      await _anakService.deleteAnak(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data anak berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
      _loadAnakData(); // Reload data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus data anak: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _calculateAge(String birthDateString) {
    try {
      DateTime birthDate = DateTime.parse(birthDateString);
      DateTime currentDate = DateTime.now();
      
      // Hitung total usia dalam hari
      int totalDays = currentDate.difference(birthDate).inDays;
      
      // Konversi ke bulan dan hari
      int months = totalDays ~/ 30; // Aproximasi 1 bulan = 30 hari
      int days = totalDays % 30;
      
      return '$months bulan $days hari';
    } catch (e) {
      return 'Error';
    }
  }

  void _navigateToJadwalForChild(BuildContext context, Map<String, dynamic> anak) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PenjadwalanScreen(
          anakId: anak['id'],
        ),
      ),
    ).then((_) {
      // Refresh data anak setelah kembali dari halaman jadwal
      _loadAnakData();
    });
  }

  void _showEditAnakDialog(BuildContext context, Map<String, dynamic> anak) {
    final nameController = TextEditingController(text: anak['nama_anak']);
    final birthPlaceController = TextEditingController(text: anak['tempat_lahir']);
    final birthDateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.parse(anak['tanggal_lahir']))
    );
    final genderController = TextEditingController(text: anak['jenis_kelamin']);
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    DateTime? selectedDate;

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
                  Text('Edit Data Anak'),
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
                          labelText: 'Nama Anak',
                          prefixIcon: Icon(Icons.child_care),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama anak tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: birthPlaceController,
                        decoration: InputDecoration(
                          labelText: 'Tempat Lahir',
                          prefixIcon: Icon(Icons.location_city),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tempat lahir tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: birthDateController,
                        decoration: InputDecoration(
                          labelText: 'Tanggal Lahir',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.date_range),
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate ?? DateTime.parse(anak['tanggal_lahir']),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  selectedDate = picked;
                                  birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                                });
                              }
                            },
                          ),
                        ),
                        readOnly: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tanggal lahir tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: genderController.text,
                        decoration: InputDecoration(
                          labelText: 'Jenis Kelamin',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: ['Laki-laki', 'Perempuan'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            genderController.text = newValue!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Jenis kelamin harus dipilih';
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
                        // Parse tanggal lahir
                        final tanggalLahir = DateTime.parse(birthDateController.text);
                        
                        // Panggil updateAnak dengan parameter yang benar
                        await _anakService.updateAnak(
                          anakId: anak['id'],
                          namaAnak: nameController.text,
                          tempatLahir: birthPlaceController.text,
                          tanggalLahir: tanggalLahir,
                          jenisKelamin: genderController.text,
                        );
                        
                        if (mounted) {
                          Navigator.pop(context, true); // Return true to indicate success
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Data anak berhasil diperbarui'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadAnakData(); // Refresh data setelah update
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal memperbarui data anak: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Anak', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade50, Colors.white],
          ),
        ),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade700),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  await _loadParentData();
                  await _loadAnakData();
                },
                color: Colors.teal.shade700,
                child: _anakList.isEmpty
                  ? _buildEmptyState()
                  : _buildAnakList(),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnakFormScreen(),
            ),
          ).then((result) {
            if (result == true) {
              _loadAnakData();
            }
          });
        },
        backgroundColor: Colors.teal.shade700,
        child: Icon(Icons.add),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
  
  // Widget untuk menampilkan pesan ketika data kosong
  Widget _buildEmptyState() {
    return ListView(
      // Gunakan ListView agar RefreshIndicator berfungsi dengan baik
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.child_care,
                  size: 80,
                  color: Colors.teal.shade700,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Belum ada data anak',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
              ),
              SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Tambahkan data anak dengan menekan tombol + di bawah',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 16, color: Colors.teal.shade700),
                    SizedBox(width: 8),
                    Text(
                      'Tarik ke bawah untuk menyegarkan data',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.teal.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Widget untuk menampilkan daftar anak
  Widget _buildAnakList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _anakList.length,
      itemBuilder: (context, index) {
        final anak = _anakList[index];
        final tanggalLahir = DateTime.parse(anak['tanggal_lahir']);
        final usia = _calculateAge(anak['tanggal_lahir']);
        
        // Informasi pengguna (parent)
        final pengguna = anak['pengguna']; // Jika API mengembalikan data nested
        //final penggunaId = anak['pengguna_id'];
        
        // Dapatkan data pengguna dari API atau dari SharedPreferences
        String namaIbu = 'Ibu'; // Default ke 'Ibu' bukan 'Tidak Tersedia'
        String nikIbu = 'Tidak Tersedia';
        
        if (pengguna != null) {
          // Data dari API
          namaIbu = pengguna['nama'] ?? 'Ibu';
          nikIbu = pengguna['nik'] ?? 'Tidak Tersedia';
          print('Data ibu dari API: $namaIbu (NIK: $nikIbu)');
        } else if (_parentData.isNotEmpty) {
          // Data dari SharedPreferences
          namaIbu = _parentData['nama'] ?? 'Ibu';
          nikIbu = _parentData['nik'] ?? 'Tidak Tersedia';
          print('Data ibu dari SharedPreferences: $namaIbu (NIK: $nikIbu)');
        } else {
          print('Data pengguna tidak tersedia untuk anak ID ${anak['id']}');
        }
        
        // Pastikan nama ibu tidak kosong
        if (namaIbu.isEmpty) {
          namaIbu = 'Ibu';
        }
        
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: anak['jenis_kelamin'] == 'Laki-laki' 
                ? [Colors.blue.shade50, Colors.teal.shade50] 
                : [Colors.pink.shade50, Colors.teal.shade50],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: anak['jenis_kelamin'] == 'Laki-laki'
                                    ? Colors.blue.shade300
                                    : Colors.pink.shade300,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundColor: anak['jenis_kelamin'] == 'Laki-laki'
                                  ? Colors.blue.shade100
                                  : Colors.pink.shade100,
                              radius: 26,
                              child: Icon(
                                anak['jenis_kelamin'] == 'Laki-laki'
                                    ? Icons.boy
                                    : Icons.girl,
                                color: anak['jenis_kelamin'] == 'Laki-laki'
                                    ? Colors.blue.shade800
                                    : Colors.pink.shade800,
                                size: 30,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  anak['nama_anak'] ?? '-',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                // Usia removed from here as it's already displayed below
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: PopupMenuButton(
                        icon: Icon(Icons.more_vert, color: Colors.teal.shade700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditAnakDialog(context, anak);
                          } else if (value == 'delete') {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Konfirmasi'),
                                content: Text(
                                  'Apakah Anda yakin ingin menghapus data ${anak['nama_anak']}?'
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('BATAL'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _deleteAnak(anak['id']);
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: Text('HAPUS'),
                                  ),
                                ],
                              ),
                            );
                          } else if (value == 'jadwal') {
                            _navigateToJadwalForChild(context, anak);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Hapus'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'jadwal',
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 20, color: Colors.teal),
                                SizedBox(width: 8),
                                Text('Lihat Jadwal Anak'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.teal.shade200.withOpacity(0.5),
                ),
                SizedBox(height: 16),
                _buildInfoSection([
                  _infoItemCard(
                    'Tempat Lahir',
                    anak['tempat_lahir'] ?? '-',
                    Icons.location_city,
                    Colors.indigo,
                  ),
                  _infoItemCard(
                    'Tanggal Lahir',
                    DateFormat('dd MMM yyyy').format(tanggalLahir),
                    Icons.calendar_today,
                    Colors.green.shade700,
                  ),
                ]),
                SizedBox(height: 8),
                _buildInfoSection([
                  _infoItemCard(
                    'Jenis Kelamin',
                    anak['jenis_kelamin'] ?? '-',
                    anak['jenis_kelamin'] == 'Laki-laki'
                        ? Icons.male
                        : Icons.female,
                    anak['jenis_kelamin'] == 'Laki-laki'
                        ? Colors.blue.shade700
                        : Colors.pink.shade700,
                  ),
                  _infoItemCard(
                    'Nama Ibu',
                    namaIbu,
                    Icons.person,
                    Colors.purple.shade700,
                  ),
                ]),
                SizedBox(height: 8),
                _buildInfoSection([
                  _infoItemCard(
                    'Usia Anak',
                    usia,
                    Icons.watch_later_outlined,
                    Colors.orange.shade700,
                  ),
                  _infoItemCard(
                    'NIK Ibu',
                    nikIbu,
                    Icons.badge,
                    Colors.brown.shade700,
                  ),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(List<Widget> children) {
    return Row(
      children: children.map((child) => Expanded(child: child)).toList(),
    );
  }

  Widget _infoItemCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.8),
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: color,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 