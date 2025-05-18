import 'package:flutter/material.dart';
import 'package:posyandu/models/profile_model.dart';
import 'package:posyandu/services/profile_service.dart';

class ProfileController extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = false;
  String? _error;
  ProfileModel? _profile;

  bool get isLoading => _isLoading;
  String? get error => _error;
  ProfileModel? get profile => _profile;

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _profileService.getProfile();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateProfile(ProfileModel updatedProfile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _profileService.updateProfile(updatedProfile);
      _profile = updatedProfile;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _profileService.logout();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 