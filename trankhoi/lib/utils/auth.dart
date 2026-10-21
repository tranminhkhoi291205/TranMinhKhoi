import 'package:trankhoi/services/auth_service.dart';

class Auth {
  static final AuthService _service = AuthService();

  static Future<Map<String, dynamic>> login(String username, String password) async {
    return await _service.login(username, password);
  }

  static Future<Map<String, dynamic>> verifyOtp(String username, String otp, {String? deviceId}) async {
    return await _service.verifyOtp(username, otp, deviceId: deviceId);
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String hoTen,
    String? soDienThoai,
  }) async {
    return await _service.register(
      username: username,
      email: email,
      password: password,
      hoTen: hoTen,
      soDienThoai: soDienThoai,
    );
  }

  static Future<Map<String, dynamic>> verifyEmail(String username, String otp) async {
    return await _service.verifyEmail(username, otp);
  }

  static Future<Map<String, dynamic>> resendOtp(String username, {String mucDich = "DangNhap"}) async {
    return await _service.resendOtp(username, mucDich: mucDich);
  }

  static Future<void> logout() async {
    await AuthService.logout();
  }

  static Future<bool> isLoggedIn() async {
    return await AuthService.isLoggedIn();
  }

  static Future<Map<String, dynamic>?> getMe() async {
    return await _service.getMe();
  }

  static Future<String> getRole() async {
    return await AuthService.getRole();
  }
}
