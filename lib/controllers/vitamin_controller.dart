import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vitamin_model.dart';
import '../services/vitamin_service.dart';

class VitaminController {
  final VitaminService _vitaminService = VitaminService();
  final List<Vitamin> vitaminList = [];
  Map<String, dynamic>? anakData;
  late int anakId;
  bool isLoading = false;
  
  // Key for caching data
  static const String _cacheKeyPrefix = 'vitamin_data_';
  static const String _anakDataCacheKeyPrefix = 'anak_data_';
  
  // Initialize with default data from model for immediate display
  VitaminController() {
    vitaminList.addAll([
      Vitamin(
        id: 1,
        jenis: 'Vitamin A (Biru)',
        usia: '6 bulan',
        tanggal: '5 Februari 2024',
        status: 'Sudah',
        deskripsi: 'Pemberian vitamin A dosis 100.000 IU untuk pertama kali',
        lokasi: 'Posyandu Melati',
        manfaat: 'Membantu pertumbuhan dan perkembangan mata, menjaga daya tahan tubuh, dan membantu pembentukan sel-sel kulit.',
        color: Colors.blue,
      ),
      Vitamin(
        id: 2,
        jenis: 'Vitamin A (Merah)',
        usia: '12 bulan',
        tanggal: '5 Agustus 2024',
        status: 'Jadwal',
        deskripsi: 'Pemberian vitamin A dosis 200.000 IU setelah 6 bulan dari pemberian pertama',
        lokasi: 'Posyandu Melati',
        manfaat: 'Membantu pertumbuhan dan perkembangan mata, menjaga daya tahan tubuh, dan membantu pembentukan sel-sel kulit.',
        color: Colors.red,
      ),
      Vitamin(
        id: 3,
        jenis: 'Vitamin A (Merah)',
        usia: '18 bulan',
        tanggal: '5 Februari 2025',
        status: 'Belum',
        deskripsi: 'Pemberian vitamin A dosis 200.000 IU',
        lokasi: 'Posyandu Melati',
        manfaat: 'Membantu pertumbuhan dan perkembangan mata, menjaga daya tahan tubuh, dan membantu pembentukan sel-sel kulit.',
        color: Colors.red,
      ),
    ]);
  }
  
  // Fetch vitamin data for a specific child from API or cache
  Future<void> fetchVitaminData(int childId) async {
    try {
      isLoading = true;
      anakId = childId;
      
      // Check cache first
      final cachedData = await _getCachedVitaminData(childId);
      if (cachedData != null) {
        print('Using cached vitamin data for child ID: $childId');
        _populateVitaminList(cachedData);
        isLoading = false;
      }
      
      // Always fetch fresh data from API
      try {
        print('Fetching fresh vitamin data for child ID: $childId');
        final apiData = await _vitaminService.getVitaminByAnakId(childId);
        
        // Cache the API data
        await _cacheVitaminData(childId, apiData);
        
        // Update the list with API data
        _populateVitaminList(apiData);
      } catch (apiError) {
        print('Error fetching vitamin data: $apiError');
        // If contains "Data anak tidak ditemukan", rethrow it
        if (apiError.toString().contains('Data anak tidak ditemukan')) {
          throw Exception('Data anak tidak ditemukan');
        }
        // If we have cached data, continue without error
        if (cachedData == null) {
          throw apiError; // Only throw if we have no cached data
        }
      } finally {
        isLoading = false;
      }
    } catch (e) {
      print('Error fetching vitamin data: $e');
      isLoading = false;
      throw e; // Rethrow so UI can handle it
    }
  }
  
  // Fetch child's data
  Future<void> fetchAnakData(int childId) async {
    try {
      // Check cache first
      final cachedAnakData = await _getCachedAnakData(childId);
      if (cachedAnakData != null) {
        print('Using cached anak data for child ID: $childId');
        anakData = cachedAnakData;
      }
      
      // Always fetch fresh data
      try {
        print('Fetching fresh anak data for child ID: $childId');
        final apiAnakData = await _vitaminService.getAnakData(childId);
        
        // Cache the API data
        await _cacheAnakData(childId, apiAnakData);
        
        // Update anak data
        anakData = apiAnakData;
        print('Retrieved anak data: $anakData');
      } catch (apiError) {
        print('Error fetching anak data: $apiError');
        // If we have no cached data at all, rethrow
        if (cachedAnakData == null || apiError.toString().contains('Data anak tidak ditemukan')) {
          throw apiError;
        }
        // Otherwise continue with cached data
      }
    } catch (e) {
      print('Error fetching anak data: $e');
      throw e; // Rethrow for UI handling
    }
  }
  
  // Update vitamin status
  Future<bool> updateVitaminStatus(int vitaminId, String newStatus) async {
    try {
      final updatedVitamin = await _vitaminService.updateVitaminStatus(
        vitaminId, 
        newStatus
      );
      
      // Update local list
      final index = vitaminList.indexWhere((v) => v.id == vitaminId);
      if (index != -1) {
        vitaminList[index] = Vitamin.fromJson(updatedVitamin);
      }
      
      // Update cache
      await _refreshCachedVitaminData(anakId);
      
      return true;
    } catch (e) {
      print('Error updating vitamin status: $e');
      return false;
    }
  }
  
  // Get a count of vitamins by status
  int getCountByStatus(String status) {
    // Handle both variations of completed status
    if (status.toLowerCase() == 'sudah') {
      return vitaminList.where((v) => 
        v.status.toLowerCase() == 'sudah' ||
        v.status.toLowerCase() == 'selesai' ||
        v.status.toLowerCase().contains('sudah') ||
        v.status.toLowerCase().contains('selesai')
      ).length;
    }
    
    return vitaminList.where((v) => v.status.toLowerCase() == status.toLowerCase()).length;
  }
  
  // Populate vitamin list from API data
  void _populateVitaminList(List<dynamic> apiData) {
    vitaminList.clear();
    
    for (var item in apiData) {
      vitaminList.add(Vitamin.fromJson(item));
    }
  }
  
  // Cache vitamin data
  Future<void> _cacheVitaminData(int childId, List<dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$childId';
      
      // Convert data to JSON string
      final dataStr = jsonEncode(data);
      
      // Save to SharedPreferences
      await prefs.setString(cacheKey, dataStr);
      print('Cached vitamin data for child ID: $childId');
    } catch (e) {
      print('Error caching vitamin data: $e');
    }
  }
  
  // Get cached vitamin data
  Future<List<dynamic>?> _getCachedVitaminData(int childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$childId';
      
      final dataStr = prefs.getString(cacheKey);
      if (dataStr != null) {
        // Parse the string back to list of maps
        return jsonDecode(dataStr) as List<dynamic>;
      }
      return null;
    } catch (e) {
      print('Error retrieving cached vitamin data: $e');
      return null;
    }
  }
  
  // Update cached vitamin data after a change
  Future<void> _refreshCachedVitaminData(int childId) async {
    try {
      final apiData = await _vitaminService.getVitaminByAnakId(childId);
      await _cacheVitaminData(childId, apiData);
    } catch (e) {
      print('Error refreshing cached vitamin data: $e');
    }
  }
  
  // Cache anak data
  Future<void> _cacheAnakData(int childId, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_anakDataCacheKeyPrefix$childId';
      
      // Convert data to JSON string
      final dataStr = jsonEncode(data);
      
      // Save to SharedPreferences
      await prefs.setString(cacheKey, dataStr);
      print('Cached anak data for child ID: $childId');
    } catch (e) {
      print('Error caching anak data: $e');
    }
  }
  
  // Get cached anak data
  Future<Map<String, dynamic>?> _getCachedAnakData(int childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_anakDataCacheKeyPrefix$childId';
      
      final dataStr = prefs.getString(cacheKey);
      if (dataStr != null) {
        // Parse the string back to map
        return jsonDecode(dataStr) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error retrieving cached anak data: $e');
      return null;
    }
  }
  
  // Calculate and return child's age as a formatted string
  String getChildAge() {
    if (anakData == null) return '';
    
    // Check for various age data formats
    String formattedAge = '';
    
    try {
      // Try to get from umur_bulan and umur_hari if available
      if (anakData!.containsKey('umur_bulan') && anakData!['umur_bulan'] != null) {
        int bulan = anakData!['umur_bulan'];
        int hari = anakData!.containsKey('umur_hari') ? anakData!['umur_hari'] ?? 0 : 0;
        
        if (bulan > 0) {
          formattedAge = '$bulan bulan';
          if (hari > 0) {
            formattedAge += ' $hari hari';
          }
        } else if (hari > 0) {
          formattedAge = '$hari hari';
        }
      } 
      // If umur_bulan/umur_hari not available, calculate from tanggal_lahir
      else if (anakData!.containsKey('tanggal_lahir') && anakData!['tanggal_lahir'] != null) {
        DateTime birthDate = DateTime.parse(anakData!['tanggal_lahir']);
        DateTime now = DateTime.now();
        
        int years = now.year - birthDate.year;
        int months = now.month - birthDate.month;
        int days = now.day - birthDate.day;
        
        if (days < 0) {
          months--;
          days += 30; // Approximate days in a month
        }
        
        if (months < 0) {
          years--;
          months += 12;
        }
        
        if (years > 0) {
          formattedAge = '$years tahun';
          if (months > 0) {
            formattedAge += ' $months bulan';
          }
        } else if (months > 0) {
          formattedAge = '$months bulan';
          if (days > 0) {
            formattedAge += ' $days hari';
          }
        } else {
          formattedAge = '$days hari';
        }
      }
      
      print('Calculated age: $formattedAge');
      return formattedAge;
    } catch (e) {
      print('Error calculating age: $e');
      return '';
    }
  }
} 