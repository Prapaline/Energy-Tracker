import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  static const _key = 'jwt';
  static final _secureStorage = FlutterSecureStorage();

  //écrire le token
  static Future<void> writeToken(String token) async {
    if (kIsWeb) {
      //Web : utilisation de SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, token);
    } else {
      //utilisation de Mobile : SecureStorage
      await _secureStorage.write(key: _key, value: token);
    }
  }

  //Lire le token
  static Future<String?> readToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key);
    } else {
      return await _secureStorage.read(key: _key);
    }
  }

  //Supprimer le token
  static Future<void> deleteToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } else {
      await _secureStorage.delete(key: _key);
    }
  }
}
