import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service untuk load environment variables dari .env file
/// Gunakan untuk manage secrets dan configuration
class EnvService {
  static final EnvService _instance = EnvService._internal();
  static final Map<String, String> _env = {};
  static bool _initialized = false;

  factory EnvService() {
    return _instance;
  }

  EnvService._internal();

  /// Initialize environment variables dari .env file
  /// HARUS dipanggil di main() sebelum runApp()
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final envFile = File('.env');

      if (envFile.existsSync()) {
        final content = await envFile.readAsString();
        _parseEnvFile(content);
        debugPrint('EnvService: Loaded .env file successfully');
      } else {
        debugPrint('EnvService: .env file not found, using defaults');
      }
    } catch (e) {
      debugPrint('EnvService: Error loading .env file: $e');
    }

    _initialized = true;
  }

  /// Parse .env file content
  static void _parseEnvFile(String content) {
    final lines = content.split('\n');
    for (final line in lines) {
      if (line.isEmpty || line.startsWith('#')) continue;

      final parts = line.split('=');
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = parts[1].trim();
        _env[key] = value;
      }
    }
  }

  /// Get environment variable
  static String get(String key, [String defaultValue = '']) {
    return _env[key] ?? defaultValue;
  }

  /// Get required environment variable (throws if not found)
  static String getRequired(String key) {
    final value = _env[key];
    if (value == null || value.isEmpty) {
      throw Exception('Environment variable "$key" is required but not set');
    }
    return value;
  }

  /// Get boolean environment variable
  static bool getBool(String key, [bool defaultValue = false]) {
    final value = _env[key];
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true' || value == '1';
  }

  /// Get all environment variables (for debugging)
  static Map<String, String> getAll() => Map.from(_env);

  /// Check if in production
  static bool get isProduction =>
      get('ENVIRONMENT', 'development') == 'production';

  /// Check if in development
  static bool get isDevelopment =>
      get('ENVIRONMENT', 'development') == 'development';
}
