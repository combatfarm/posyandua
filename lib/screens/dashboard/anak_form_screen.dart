import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:posyandu/services/anak_service.dart';

class AnakFormScreen extends StatefulWidget {
  final int? anakId; // Jika tidak null, berarti edit data yang sudah ada

  const AnakFormScreen({Key? key, this.anakId}) : super(key: key);

  @override
  _AnakFormScreenState createState() => _AnakFormScreenState();
}

class _AnakFormScreenState extends State<AnakFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _tempatLahirController = TextEditingController();
  final TextEditingController _tanggalLahirController = TextEditingController();
  DateTime? _selectedDate;
  String _jenisKelamin = 'Laki-laki'; // Default value
  bool _isLoading = false;
  bool _isEdit = false;
  
  final AnakService _anakService = AnakService();

  @override
  void initState() {
    super.initState();
    _isEdit = widget.anakId != null;
    if (_isEdit) {
      // Jika mode edit, load data anak
      _loadAnakData();
    }
  }

  Future<void> _loadAnakData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.anakId != null) {
        final anak = await _anakService.getAnakDetail(widget.anakId!);
        
        _namaController.text = anak['nama_anak'];
        _tempatLahirController.text = anak['tempat_lahir'];
        
        // Format tanggal
        final DateTime tanggalLahir = DateTime.parse(anak['tanggal_lahir']);
        _selectedDate = tanggalLahir;
        _tanggalLahirController.text = DateFormat('dd-MM-yyyy').format(tanggalLahir);
        
        setState(() {
          _jenisKelamin = anak['jenis_kelamin'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data anak: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Pilih Tanggal Lahir',
      cancelText: 'BATAL',
      confirmText: 'PILIH',
      fieldLabelText: 'Tanggal Lahir Anak',
      fieldHintText: 'DD/MM/YYYY',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal.shade700,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tanggalLahirController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Future<void> _saveData() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        Map<String, dynamic> response;
        
        if (_selectedDate == null) {
          throw Exception('Tanggal lahir harus diisi');
        }
        
        print('Menyimpan data anak...');
        
        try {
          if (_isEdit && widget.anakId != null) {
            // Update existing data
            response = await _anakService.updateAnak(
              anakId: widget.anakId!,
              namaAnak: _namaController.text,
              tempatLahir: _tempatLahirController.text,
              tanggalLahir: _selectedDate!,
              jenisKelamin: _jenisKelamin,
            );
          } else {
            // Create new data
            response = await _anakService.createAnak(
              namaAnak: _namaController.text,
              tempatLahir: _tempatLahirController.text,
              tanggalLahir: _selectedDate!,
              jenisKelamin: _jenisKelamin,
            );
          }
          print('Response dari server: $response');
        } catch (e) {
          print('Error dari API: $e');
          throw Exception('Gagal mengirim data ke server: $e');
        }

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        if (response['success'] == true) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEdit ? 'Data anak berhasil diperbarui' : 'Data anak berhasil disimpan'),
              backgroundColor: Colors.green,
            ),
          );
          
          print('Data anak berhasil disimpan. Kembali ke halaman sebelumnya dengan result=true');
          
          // Go back to previous screen with result=true to trigger reload
          Navigator.pop(context, true);
        } else {
          // Show error message
          String errorMsg = response['message'] ?? 'Terjadi kesalahan';
          if (response.containsKey('errors')) {
            errorMsg += ': ${response['errors']}';
          }
          print('Error dari server: $errorMsg');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Error saat menyimpan: $e');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _tempatLahirController.dispose();
    _tanggalLahirController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Data Anak' : 'Tambah Data Anak'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informasi Anak
                    _buildSectionTitle('Informasi Anak'),
                    SizedBox(height: 16),
                    
                    // Nama Anak
                    TextFormField(
                      controller: _namaController,
                      decoration: InputDecoration(
                        labelText: 'Nama Anak',
                        hintText: 'Masukkan nama lengkap anak',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama anak harus diisi';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Tempat Lahir
                    TextFormField(
                      controller: _tempatLahirController,
                      decoration: InputDecoration(
                        labelText: 'Tempat Lahir',
                        hintText: 'Masukkan tempat lahir anak',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tempat lahir harus diisi';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Tanggal Lahir
                    TextFormField(
                      controller: _tanggalLahirController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Tanggal Lahir',
                        hintText: 'Pilih tanggal lahir anak',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.date_range),
                          onPressed: () => _selectDate(context),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tanggal lahir harus diisi';
                        }
                        return null;
                      },
                      onTap: () => _selectDate(context),
                    ),
                    SizedBox(height: 16),
                    
                    // Jenis Kelamin
                    _buildSectionTitle('Jenis Kelamin'),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text('Laki-laki'),
                            value: 'Laki-laki',
                            groupValue: _jenisKelamin,
                            activeColor: Colors.teal.shade700,
                            onChanged: (value) {
                              setState(() {
                                _jenisKelamin = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text('Perempuan'),
                            value: 'Perempuan',
                            groupValue: _jenisKelamin,
                            activeColor: Colors.teal.shade700,
                            onChanged: (value) {
                              setState(() {
                                _jenisKelamin = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    
                    // Submit Button
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          textStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(_isEdit ? 'PERBARUI DATA' : 'SIMPAN DATA'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.teal.shade800,
      ),
    );
  }
} 