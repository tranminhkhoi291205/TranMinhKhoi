import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> authenticate() async {
    try {
      final bool authenticated = await _auth.authenticate(
        localizedReason: 'Xác thực vân tay / khuôn mặt để đăng nhập',
      );
      if (authenticated) {
        return {'success': true, 'message': 'Xác thực sinh trắc học thành công'};
      }
      return {'success': false, 'message': 'Xác thực thất bại hoặc bị hủy'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi sinh trắc học: $e'};
    }
  }
}
