import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../config/constants.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  String _language = 'ar';
  String _theme = 'dark';
  bool _isLoading = false;
  List<UserModel> _savedAccounts = [];
  String? _chatBackground;
  Map<String, dynamic> _privacySettings = {};

  UserModel? get currentUser => _currentUser;
  String get language => _language;
  String get theme => _theme;
  bool get isDarkTheme => _theme == 'dark';
  bool get isLoading => _isLoading;
  List<UserModel> get savedAccounts => _savedAccounts;
  String? get chatBackground => _chatBackground;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  Map<String, dynamic> get privacySettings => _privacySettings;

  void setLoading(bool val) { _isLoading = val; notifyListeners(); }

  void setUser(UserModel? user) {
    _currentUser = user;
    if (user != null) {
      _language = user.settings['language'] ?? 'ar';
      _theme = user.settings['theme'] ?? 'dark';
      _chatBackground = user.settings['chatBackground'];
      _privacySettings = Map<String, dynamic>.from(user.privacy);
    }
    notifyListeners();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString(AppConstants.prefLanguage) ?? 'ar';
    _theme = prefs.getString(AppConstants.prefTheme) ?? 'dark';
    notifyListeners();
    final user = await _authService.loadSession();
    if (user != null) setUser(user);
    _savedAccounts = await _authService.getSavedAccounts();
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(AppConstants.prefLanguage, lang);
    if (_currentUser != null) {
      final settings = Map<String, dynamic>.from(_currentUser!.settings);
      settings['language'] = lang;
      await _authService.updateProfile(settings: settings);
    }
    notifyListeners();
  }

  Future<void> setTheme(String t) async {
    _theme = t;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(AppConstants.prefTheme, t);
    if (_currentUser != null) {
      final settings = Map<String, dynamic>.from(_currentUser!.settings);
      settings['theme'] = t;
      await _authService.updateProfile(settings: settings);
    }
    notifyListeners();
  }

  Future<void> updatePrivacy(Map<String, dynamic> privacy) async {
    _privacySettings = privacy;
    await _authService.updateProfile(privacy: privacy);
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _savedAccounts = await _authService.getSavedAccounts();
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_currentUser == null) return;
    final user = await _authService.getUserById(_currentUser!.id);
    if (user != null) setUser(user);
  }

  Future<void> refreshSavedAccounts() async {
    _savedAccounts = await _authService.getSavedAccounts();
    notifyListeners();
  }

  Future<void> switchAccount(String userId) async {
    final user = await _authService.switchAccount(userId);
    if (user != null) {
      setUser(user);
      _savedAccounts = await _authService.getSavedAccounts();
    }
  }

  Locale get locale => Locale(_language);
  ThemeMode get themeMode {
    switch (_theme) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }
}
