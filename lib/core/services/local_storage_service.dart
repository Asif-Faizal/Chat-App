import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token management (secure storage)
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  Future<void> removeToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }

  // User data management (regular storage)
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    if (_prefs != null) {
      await _prefs!.setString('user_data', jsonEncode(userData));
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    if (_prefs != null) {
      final userDataString = _prefs!.getString('user_data');
      if (userDataString != null) {
        return jsonDecode(userDataString) as Map<String, dynamic>;
      }
    }
    return null;
  }

  Future<void> removeUserData() async {
    if (_prefs != null) {
      await _prefs!.remove('user_data');
    }
  }

  // User ID
  Future<void> saveUserId(String userId) async {
    if (_prefs != null) {
      await _prefs!.setString('user_id', userId);
    }
  }

  Future<String?> getUserId() async {
    if (_prefs != null) {
      return _prefs!.getString('user_id');
    }
    return null;
  }

  // User role
  Future<void> saveUserRole(String role) async {
    if (_prefs != null) {
      await _prefs!.setString('user_role', role);
    }
  }

  Future<String?> getUserRole() async {
    if (_prefs != null) {
      return _prefs!.getString('user_role');
    }
    return null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Clear all data (logout)
  Future<void> clearAll() async {
    await removeToken();
    await removeUserData();
    if (_prefs != null) {
      await _prefs!.remove('user_id');
      await _prefs!.remove('user_role');
    }
  }

  // Save last login method
  Future<void> saveLastLoginMethod(String method) async {
    if (_prefs != null) {
      await _prefs!.setString('last_login_method', method);
    }
  }

  Future<String?> getLastLoginMethod() async {
    if (_prefs != null) {
      return _prefs!.getString('last_login_method');
    }
    return null;
  }
}