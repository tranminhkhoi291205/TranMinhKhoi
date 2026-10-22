import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigUrl {
  static const String defaultConveyorUrl = "https://largetealbike39.conveyor.cloud/api/";
  static const String defaultEmulatorUrl = "http://10.0.2.2:5145/api/";
  static const String defaultLanUrl = "http://192.168.1.3:5145/api/";
  static const String defaultLocalhostUrl = "http://localhost:5145/api/";

  static String _currentBaseUrl = "";

  static String get baseUrl {
    if (_currentBaseUrl.isNotEmpty) {
      return _currentBaseUrl;
    }
    try {
      final envUrl = dotenv.env['BASE_URL'];
      if (envUrl != null && envUrl.isNotEmpty) {
        _currentBaseUrl = envUrl.endsWith('/') ? envUrl : '$envUrl/';
        return _currentBaseUrl;
      }
    } catch (_) {
      // Bỏ qua lỗi nếu dotenv chưa được khởi tạo
    }

    // Nếu không đọc được URL trong file .env thì dùng default Conveyor Cloud
    // ignore: avoid_print
    print("BASE_URL is not set in the .env file. Using default URL: $defaultConveyorUrl");
    _currentBaseUrl = defaultConveyorUrl;
    return _currentBaseUrl;
  }

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('custom_base_url');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _currentBaseUrl = savedUrl.endsWith('/') ? savedUrl : '$savedUrl/';
        return;
      }
    } catch (_) {}

    try {
      final envUrl = dotenv.env['BASE_URL'];
      if (envUrl != null && envUrl.isNotEmpty) {
        _currentBaseUrl = envUrl.endsWith('/') ? envUrl : '$envUrl/';
        return;
      }
    } catch (_) {}

    // ignore: avoid_print
    print("BASE_URL is not set in the .env file. Using default URL: $defaultConveyorUrl");
    _currentBaseUrl = defaultConveyorUrl;
  }

  static Future<void> setBaseUrl(String newUrl) async {
    String formatted = newUrl.trim();
    if (!formatted.endsWith('/')) {
      formatted = '$formatted/';
    }
    _currentBaseUrl = formatted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_base_url', formatted);
    } catch (_) {}
  }
}

// Hỗ trợ cả 2 định dạng gọi: ConfigUrl hoặc Config_URL
// ignore: camel_case_types
typedef Config_URL = ConfigUrl;
