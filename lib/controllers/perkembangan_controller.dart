import 'package:flutter/material.dart';
import '../models/perkembangan_model.dart';

class PerkembanganController {
  List<GrowthData> _growthData = [];
  List<Milestone> _milestones = [];
  List<Note> _notes = [];

  // Getters
  List<GrowthData> get growthData => _growthData;
  List<Milestone> get milestones => _milestones;
  List<Note> get notes => _notes;

  // Constructor
  PerkembanganController() {
    _initializeData();
  }

  // Inisialisasi data
  void _initializeData() {
    // Initialize growth data
    _growthData = [
      GrowthData(month: 12, height: 75.0, weight: 9.5),
      GrowthData(month: 13, height: 76.2, weight: 9.8),
      GrowthData(month: 14, height: 77.5, weight: 10.1),
      GrowthData(month: 15, height: 78.2, weight: 10.3),
      GrowthData(month: 16, height: 79.3, weight: 10.5),
      GrowthData(month: 17, height: 80.0, weight: 10.8),
      GrowthData(month: 18, height: 81.2, weight: 11.0),
    ];

    // Initialize milestones
    _milestones = [
      Milestone(
        age: '12 bulan',
        achieved: true,
        title: 'Berdiri dengan bantuan',
        description: 'Anak dapat berdiri dengan berpegangan pada objek atau bantuan orang lain',
        icon: Icons.accessibility_new,
      ),
      Milestone(
        age: '13 bulan',
        achieved: true,
        title: 'Mengucapkan kata pertama',
        description: 'Anak mulai mengucapkan kata-kata yang bermakna seperti "mama" atau "papa"',
        icon: Icons.record_voice_over,
      ),
      Milestone(
        age: '15 bulan',
        achieved: true,
        title: 'Berjalan tanpa bantuan',
        description: 'Anak dapat berjalan beberapa langkah tanpa perlu berpegangan',
        icon: Icons.directions_walk,
      ),
      Milestone(
        age: '18 bulan',
        achieved: false,
        title: 'Menumpuk balok',
        description: 'Anak dapat menumpuk 2-3 balok atau objek',
        icon: Icons.widgets,
      ),
      Milestone(
        age: '18 bulan',
        achieved: false,
        title: 'Menunjuk bagian tubuh',
        description: 'Anak dapat menunjuk bagian tubuh seperti mata, hidung, atau mulut ketika diminta',
        icon: Icons.face,
      ),
    ];

    // Initialize notes
    _notes = [
      Note(
        date: '18 Februari 2025',
        title: 'Kunjungan Dokter Anak',
        content: 'Dokter menyatakan perkembangan normal. Tumbuh gigi baru, sudah dapat berjalan dengan baik.',
        color: Colors.blue.shade700,
      ),
      Note(
        date: '5 Februari 2025',
        title: 'Perkembangan Motorik',
        content: 'Mulai dapat memegang sendok dengan baik. Mencoba makan sendiri walau masih berantakan.',
        color: Colors.purple.shade700,
      ),
      Note(
        date: '20 Januari 2025',
        title: 'Perkembangan Bahasa',
        content: 'Sudah dapat mengucapkan beberapa kata dasar seperti "mama", "papa", "makan", dan "minum".',
        color: Colors.green.shade700,
      ),
    ];
  }

  // Toggle milestone achievement
  void toggleMilestoneAchievement(int index) {
    if (index >= 0 && index < _milestones.length) {
      _milestones[index] = Milestone(
        age: _milestones[index].age,
        achieved: !_milestones[index].achieved,
        title: _milestones[index].title,
        description: _milestones[index].description,
        icon: _milestones[index].icon,
      );
    }
  }

  // Add new growth data
  void addGrowthData(GrowthData data) {
    _growthData.add(data);
  }

  // Add new milestone
  void addMilestone(Milestone milestone) {
    _milestones.add(milestone);
  }

  // Add new note
  void addNote(Note note) {
    _notes.add(note);
  }

  // Get latest growth data
  GrowthData? getLatestGrowthData() {
    if (_growthData.isEmpty) return null;
    return _growthData.reduce((a, b) => a.month > b.month ? a : b);
  }

  // Get growth statistics
  Map<String, dynamic> getGrowthStats() {
    if (_growthData.isEmpty) return {};

    final latest = getLatestGrowthData()!;
    return {
      'height': {
        'value': latest.height,
        'percentile': '75%',
        'stdDev': '+1.2',
        'status': 'Normal',
      },
      'weight': {
        'value': latest.weight,
        'percentile': '60%',
        'stdDev': '+0.8',
        'status': 'Normal',
      },
    };
  }
} 