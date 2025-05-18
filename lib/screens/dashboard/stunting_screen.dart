import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/stunting_model.dart';
import '../../controllers/stunting_controller.dart';

class StuntingScreen extends StatefulWidget {
  @override
  _StuntingScreenState createState() => _StuntingScreenState();
}

class _StuntingScreenState extends State<StuntingScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'Nama Pasien': TextEditingController(),
    'Usia (bulan)': TextEditingController(),
    'Tinggi Badan (cm)': TextEditingController(),
    'Berat Badan (kg)': TextEditingController(),
    'Lingkar Kepala (cm)': TextEditingController(),
    'Catatan Tambahan': TextEditingController(),
  };
  
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late StuntingController _stuntingController;
  
  // For date selection
  DateTime _tanggalPemeriksaan = DateTime.now();

  @override
  void initState() {
    super.initState();
    _stuntingController = StuntingController();
    
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
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tanggalPemeriksaan,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.red.shade700,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _tanggalPemeriksaan) {
      setState(() {
        _tanggalPemeriksaan = picked;
      });
    }
  }
  
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      // Simulate network delay
      Future.delayed(Duration(seconds: 2), () {
        // Get form values
        double? tinggi = double.tryParse(_controllers['Tinggi Badan (cm)']!.text);
        int? usia = int.tryParse(_controllers['Usia (bulan)']!.text);
        
        if (tinggi != null && usia != null) {
          // Dummy gender for this example
          String gender = 'L';
          String status = _stuntingController.getZScoreStatus(tinggi, usia, gender);
          
          // Create new stunting data
          StuntingData newData = StuntingData(
            namaPasien: _controllers['Nama Pasien']!.text,
            usia: usia,
            tinggiBadan: tinggi,
            beratBadan: double.parse(_controllers['Berat Badan (kg)']!.text),
            lingkarKepala: double.parse(_controllers['Lingkar Kepala (cm)']!.text),
            catatanTambahan: _controllers['Catatan Tambahan']!.text,
            tanggalPemeriksaan: _tanggalPemeriksaan,
            status: status,
            gender: gender,
          );
          
          // Add to controller
          _stuntingController.addStuntingData(newData);
          
          setState(() {
            _isLoading = false;
          });
          
          // Show result dialog
          _showResultDialog(status, tinggi, usia);
        } else {
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: Data tidak valid'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }
  
  void _showResultDialog(String status, double tinggi, int usia) {
    final statusDetails = _stuntingController.getStatusDetails(status);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(statusDetails['icon'], color: statusDetails['color']),
            SizedBox(width: 8),
            Text('Hasil Pemeriksaan', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: $status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: statusDetails['color'],
              ),
            ),
            SizedBox(height: 8),
            Text('Tinggi: $tinggi cm'),
            Text('Usia: $usia bulan'),
            SizedBox(height: 16),
            Text(statusDetails['message']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Reset form for new entry
              _formKey.currentState!.reset();
              _controllers.forEach((key, controller) => controller.clear());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: Text('Pengukuran Baru'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        elevation: 0,
        title: Text(
          'Pencegahan Stunting',
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(20, 0, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Form Pengukuran',
                      style: TextStyle(
                        fontSize: screenSize.width * 0.055,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Lengkapi form di bawah untuk mendeteksi stunting',
                      style: TextStyle(
                        fontSize: screenSize.width * 0.035,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date selector
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.red.shade700),
                                  SizedBox(width: 12),
                                  Text(
                                    'Tanggal: ${_tanggalPemeriksaan.day}/${_tanggalPemeriksaan.month}/${_tanggalPemeriksaan.year}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          
                          // Form fields
                          ..._controllers.entries.map((entry) {
                            final isNumberField = entry.key.contains('(kg)') ||
                                entry.key.contains('(cm)') ||
                                entry.key.contains('(bulan)');
                                
                            IconData fieldIcon;
                            if (entry.key.contains('Nama')) {
                              fieldIcon = Icons.person;
                            } else if (entry.key.contains('Usia')) {
                              fieldIcon = Icons.calendar_month;
                            } else if (entry.key.contains('Tinggi')) {
                              fieldIcon = Icons.height;
                            } else if (entry.key.contains('Berat')) {
                              fieldIcon = Icons.monitor_weight;
                            } else if (entry.key.contains('Lingkar')) {
                              fieldIcon = Icons.radio_button_unchecked;
                            } else {
                              fieldIcon = Icons.note;
                            }
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: TextFormField(
                                controller: entry.value,
                                decoration: InputDecoration(
                                  labelText: entry.key,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.red.shade700, width: 2),
                                  ),
                                  prefixIcon: Icon(fieldIcon, color: Colors.red.shade700),
                                  floatingLabelStyle: TextStyle(color: Colors.red.shade700),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                keyboardType: isNumberField ? TextInputType.number : TextInputType.text,
                                maxLines: entry.key == 'Catatan Tambahan' ? 3 : 1,
                                inputFormatters: isNumberField 
                                    ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
                                    : null,
                                validator: (value) {
                                  if (entry.key != 'Catatan Tambahan' && (value == null || value.isEmpty)) {
                                    return '${entry.key} tidak boleh kosong';
                                  }
                                  if (isNumberField && value != null && value.isNotEmpty) {
                                    try {
                                      double.parse(value);
                                    } catch (e) {
                                      return 'Masukkan angka yang valid';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            );
                          }).toList(),
                          
                          SizedBox(height: 24),
                          
                          // Submit button
                          Container(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              onPressed: _isLoading ? null : _submitForm,
                              child: _isLoading
                                  ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.save),
                                        SizedBox(width: 8),
                                        Text(
                                          'SIMPAN & ANALISIS',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Info panel
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  color: Colors.blue.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Colors.blue.shade700,
                          size: 36,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Apa itu stunting?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Stunting adalah kondisi gagal tumbuh pada anak akibat kekurangan gizi kronis dan infeksi berulang.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
