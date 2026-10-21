import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trankhoi/config/config_url.dart';
import 'package:trankhoi/utils/auth.dart';
import 'package:trankhoi/services/biometric_service.dart';
import 'package:trankhoi/screens/admin_screen.dart';
import 'package:trankhoi/screens/customer_screen.dart';
import 'package:trankhoi/screens/main_screen.dart';
import 'package:trankhoi/screens/registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final BiometricService _biometricService = BiometricService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showOtpField = false;
  String? _activeUsername;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final loggedIn = await Auth.isLoggedIn();
    if (loggedIn) {
      final role = await Auth.getRole();
      if (!mounted) return;
      _navigateByRole(role);
    }
  }

  void _navigateByRole(String role) {
    final r = role.toLowerCase();
    if (r == 'admin' || r == 'quanly') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminScreen()),
      );
    } else if (r == 'khachhang') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CustomerScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  void _fillSampleAccount(String u, String p) {
    setState(() {
      _usernameController.text = u;
      _passwordController.text = p;
      _showOtpField = false;
      _otpController.clear();
    });
  }

  Future<void> _showServerSettings() async {
    final controller = TextEditingController(text: ConfigUrl.baseUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.dns, color: Colors.blue),
            SizedBox(width: 8),
            Text('Cấu hình Máy chủ API'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chọn nhanh địa chỉ API:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.cloud_done, size: 16, color: Colors.blue),
                  label: const Text('Conveyor Cloud (Chính)'),
                  onPressed: () => controller.text = ConfigUrl.defaultConveyorUrl,
                ),
                ActionChip(
                  label: const Text('Emulator (10.0.2.2)'),
                  onPressed: () => controller.text = ConfigUrl.defaultEmulatorUrl,
                ),
                ActionChip(
                  label: const Text('Wi-Fi LAN (192.168.1.3)'),
                  onPressed: () => controller.text = ConfigUrl.defaultLanUrl,
                ),
                ActionChip(
                  label: const Text('Localhost (5145)'),
                  onPressed: () => controller.text = ConfigUrl.defaultLocalhostUrl,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Base URL API',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              await ConfigUrl.setBaseUrl(controller.text);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã đổi API thành: ${ConfigUrl.baseUrl}')),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên đăng nhập và mật khẩu'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Nếu đang ở Bước 2 (đã có trường OTP)
    if (_showOtpField) {
      final otp = _otpController.text.trim();
      if (otp.length != 6) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập mã OTP gồm 6 chữ số'), backgroundColor: Colors.orange),
        );
        return;
      }

      final result = await Auth.verifyOtp(_activeUsername ?? username, otp, deviceId: 'MOBILE_DEVICE_DEMO_01');
      setState(() => _isLoading = false);

      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Đăng nhập thành công!'), backgroundColor: Colors.green),
        );
        _navigateByRole(result['role'] ?? 'NhanVien');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Bước 1: Gọi API login
    final result = await Auth.login(username, password);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['requiresOtp'] == true) {
      setState(() {
        _showOtpField = true;
        _activeUsername = result['username'] ?? username;
        if (result['devOtp'] != null) {
          _otpController.text = result['devOtp'].toString();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['devOtp'] != null
                ? 'Mã OTP của bạn: ${result['devOtp']} (Chế độ phát triển)'
                : (result['message'] ?? 'Mã OTP đã gửi về email của bạn!'),
          ),
          backgroundColor: Colors.blue[800],
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Đăng nhập ngay',
            textColor: Colors.white,
            onPressed: _handleLogin,
          ),
        ),
      );
    } else if (result['requiresEmailVerify'] == true) {
      _showEmailVerifyDialog(result['username'] ?? username, result['devOtp']?.toString());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  void _showEmailVerifyDialog(String username, String? devOtp) {
    final controller = TextEditingController(text: devOtp ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác thực Email tài khoản'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tài khoản $username chưa xác thực email. Vui lòng nhập mã OTP gửi tới email:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Mã OTP (6 số)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final res = await Auth.verifyEmail(username, controller.text.trim());
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res['message']), backgroundColor: res['success'] ? Colors.green : Colors.red),
              );
            },
            child: const Text('Xác thực'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBiometricLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final role = prefs.getString('user_role') ?? 'NhanVien';

    bool available = await _biometricService.isBiometricAvailable();
    if (!available) {
      if (!mounted) return;
      // Trợ giúp thuyết trình trên thiết bị giả lập Emulator
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sinh trắc học (Thuyết trình 3.5đ)'),
          content: const Text('Emulator không có phần cứng vân tay thật. Bạn có muốn kích hoạt xác thực sinh trắc học mô phỏng để thuyết trình?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xác thực thành công')),
          ],
        ),
      );
      if (confirm == true) {
        _navigateByRole(role);
      }
      return;
    }

    final res = await _biometricService.authenticate();
    if (res['success'] == true) {
      if (token != null && token.isNotEmpty) {
        _navigateByRole(role);
      } else {
        _fillSampleAccount('nhanvien01', 'NhanVien@123');
        _handleLogin();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.blue),
            tooltip: 'Cấu hình URL API',
            onPressed: _showServerSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.access_time_filled, size: 48, color: Colors.blue[800]),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'CHẤM CÔNG NHÂN VIÊN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Đăng nhập bảo mật 2 lớp (Mật khẩu + OTP Email)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Tài khoản mẫu Test nhanh
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tài khoản mẫu nhanh (Click để điền):', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), visualDensity: VisualDensity.compact),
                          onPressed: () => _fillSampleAccount('admin', 'Admin@123'),
                          child: const Text('Admin', style: TextStyle(fontSize: 12)),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), visualDensity: VisualDensity.compact),
                          onPressed: () => _fillSampleAccount('quanly01', 'QuanLy@123'),
                          child: const Text('Quản lý', style: TextStyle(fontSize: 12)),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), visualDensity: VisualDensity.compact),
                          onPressed: () => _fillSampleAccount('nhanvien01', 'NhanVien@123'),
                          child: const Text('Nhân viên', style: TextStyle(fontSize: 12)),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), visualDensity: VisualDensity.compact),
                          onPressed: () => _fillSampleAccount('khachhang01', 'KhachHang@123'),
                          child: const Text('Khách hàng', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Tên đăng nhập hoặc Email',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),

              if (_showOtpField) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.mark_email_read, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text('Nhập mã OTP 6 số từ email:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                        decoration: InputDecoration(
                          hintText: '------',
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          _showOtpField ? 'Xác Thực OTP & Vào Ứng Dụng' : 'Đăng Nhập',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _handleBiometricLogin,
                icon: const Icon(Icons.fingerprint, color: Colors.blue),
                label: const Text('Đăng nhập Vân tay / Sinh trắc học', style: TextStyle(color: Colors.blue)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có tài khoản? '),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                      );
                    },
                    child: const Text('Đăng ký ngay', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
