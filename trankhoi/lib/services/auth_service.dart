import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trankhoi/services/api_client.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  // Đăng nhập Bước 1: Username + Password
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _api.post(
        'Auth/login',
        body: {
          'username': username.trim(),
          'password': password,
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['requireOtp'] == true || data['status'] == true) {
          return {
            'success': true,
            'requiresOtp': true,
            'username': data['username'] ?? username.trim(),
            'message': data['message'] ?? 'Mật khẩu đúng. Vui lòng nhập mã OTP gửi về email!',
            'devOtp': data['devOtp'],
          };
        }
      } else if (response.statusCode == 403 && data['requireEmailVerify'] == true) {
        return {
          'success': false,
          'requiresEmailVerify': true,
          'username': data['username'] ?? username.trim(),
          'message': data['message'] ?? 'Email chưa được xác thực. Hãy nhập mã OTP để kích hoạt tài khoản!',
          'devOtp': data['devOtp'],
        };
      }

      String errorMsg = data['message'] ?? 'Sai tên đăng nhập hoặc mật khẩu.';
      return {'success': false, 'message': errorMsg};
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối đến máy chủ API: $e'};
    }
  }

  // Đăng nhập Bước 2: Nhập mã OTP -> Nhận JWT Token & Phân quyền
  Future<Map<String, dynamic>> verifyOtp(String username, String otp, {String? deviceId}) async {
    try {
      final response = await _api.post(
        'Auth/verify-otp',
        body: {
          'username': username.trim(),
          'otp': otp.trim(),
          if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId.trim(),
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final String token = data['token'];
        final String role = data['role'] ?? 'NhanVien';
        final String redirect = data['redirect'] ?? 'nhanvien';
        final int? nhanVienId = data['nhanVienId'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('user_role', role);
        await prefs.setString('user_redirect', redirect);
        await prefs.setString('user_username', username.trim());
        if (data['user'] != null) {
          await prefs.setString('user_hoten', data['user']['hoTen'] ?? '');
          await prefs.setString('user_email', data['user']['email'] ?? '');
        }
        if (nhanVienId != null) {
          await prefs.setInt('nhan_vien_id', nhanVienId);
        }

        return {
          'success': true,
          'token': token,
          'role': role,
          'redirect': redirect,
          'user': data['user'],
          'nhanVienId': nhanVienId,
          'message': data['message'] ?? 'Đăng nhập thành công!',
        };
      }

      String errorMsg = data['message'] ?? 'Mã OTP không chính xác hoặc đã hết hạn.';
      return {'success': false, 'message': errorMsg};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi xác thực OTP: $e'};
    }
  }

  // Đăng ký tài khoản qua Email
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String hoTen,
    String? soDienThoai,
  }) async {
    try {
      final response = await _api.post(
        'Auth/register',
        body: {
          'username': username.trim(),
          'email': email.trim(),
          'password': password,
          'hoTen': hoTen.trim(),
          'soDienThoai': soDienThoai?.trim(),
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        return {
          'success': true,
          'requiresOtp': true,
          'username': data['username'] ?? username.trim(),
          'message': data['message'] ?? 'Đăng ký thành công! Mã OTP đã gửi qua email.',
          'devOtp': data['devOtp'],
        };
      }

      String errorMsg = data['message'] ?? 'Đăng ký thất bại.';
      return {'success': false, 'message': errorMsg};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi đăng ký tài khoản: $e'};
    }
  }

  // Xác thực Email bằng mã OTP
  Future<Map<String, dynamic>> verifyEmail(String username, String otp) async {
    try {
      final response = await _api.post(
        'Auth/verify-email',
        body: {
          'username': username.trim(),
          'otp': otp.trim(),
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Xác thực email thành công!'};
      }
      return {'success': false, 'message': data['message'] ?? 'Xác thực email thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Gửi lại mã OTP
  Future<Map<String, dynamic>> resendOtp(String username, {String mucDich = "DangNhap"}) async {
    try {
      final response = await _api.post(
        'Auth/resend-otp',
        body: {
          'username': username.trim(),
          'mucDich': mucDich,
        },
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Đã gửi lại mã OTP.',
        'devOtp': data['devOtp'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Không thể gửi lại OTP: $e'};
    }
  }

  // Lấy thông tin user hiện tại
  Future<Map<String, dynamic>?> getMe() async {
    try {
      final response = await _api.get('Auth/me');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  // Đăng xuất
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
    await prefs.remove('user_redirect');
    await prefs.remove('user_username');
    await prefs.remove('user_hoten');
    await prefs.remove('user_email');
    await prefs.remove('nhan_vien_id');
  }

  // Kiểm tra đăng nhập
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null || token.isEmpty) return false;
    return !JwtDecoder.isExpired(token);
  }

  // Lấy vai trò hiện tại
  static Future<String> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role') ?? 'NhanVien';
  }
}
