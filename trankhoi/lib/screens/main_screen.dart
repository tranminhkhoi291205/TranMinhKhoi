import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trankhoi/utils/auth.dart';
import 'package:trankhoi/services/attendance_service.dart';
import 'package:trankhoi/services/location_service.dart';
import 'package:trankhoi/services/sensor_service.dart';
import 'package:trankhoi/screens/qr_scanner_screen.dart';
import 'package:trankhoi/screens/leave_management_screen.dart';
import 'package:trankhoi/screens/motion_sensor_screen.dart';
import 'package:trankhoi/screens/salary_estimation_screen.dart';
import 'package:trankhoi/screens/login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final LocationService _locationService = LocationService();
  final SensorService _sensorService = SensorService();

  String _userName = 'Nhân viên';
  String _userRole = 'Nhân viên';
  bool _isLoading = true;

  // Trạng thái ca làm hôm nay
  bool _daVao = false;
  bool _daRa = false;
  String _gioVao = '--:--';
  String _gioRa = '--:--';
  String _trangThaiHomNay = 'Chưa chấm công';
  int _soPhutTre = 0;
  String _locationDisplay = '';
  bool _isGettingLocation = false;

  // Điểm chuyên cần thực tế
  int _diemChuyenCan = 100;
  String _xepLoai = 'A';
  int _chuoiDungGio = 0;

  // Lịch sử gần đây
  List<dynamic> _history = [];

  // Dữ liệu cảm biến gia tốc
  double _accelX = 0.0, _accelY = 0.0, _accelZ = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadTodayData();
    _startSensor();
  }

  @override
  void dispose() {
    _sensorService.stopListening();
    super.dispose();
  }

  void _startSensor() {
    _sensorService.startListening((x, y, z) {
      if (mounted) {
        setState(() {
          _accelX = x;
          _accelY = y;
          _accelZ = z;
        });
      }
    });
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_hoten') ?? prefs.getString('user_username') ?? 'Nhân viên';
        _userRole = prefs.getString('user_role') ?? 'Nhân viên';
      });
    }
  }

  Future<void> _loadTodayData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _attendanceService.getTodayStatus(),
        _attendanceService.getMyStats(),
        _attendanceService.getMyHistory(),
      ]);

      final today = results[0] as Map<String, dynamic>?;
      final stats = results[1] as Map<String, dynamic>?;
      final history = results[2] as List<dynamic>?;

      if (mounted) {
        setState(() {
          if (today != null && today['id'] != null) {
            _daVao = today['gioVao'] != null;
            _daRa = today['gioRa'] != null;
            if (_daVao) {
              final vao = DateTime.parse(today['gioVao']);
              _gioVao = DateFormat('HH:mm').format(vao);
            }
            if (_daRa) {
              final ra = DateTime.parse(today['gioRa']);
              _gioRa = DateFormat('HH:mm').format(ra);
            }
            _soPhutTre = today['soPhutTre'] ?? 0;
            _trangThaiHomNay = today['trangThai'] == 'DungGio'
                ? 'Đúng giờ'
                : (_soPhutTre > 0 ? 'Đi trễ $_soPhutTre phút' : 'Đã chấm công');
          }

          if (stats != null) {
            final thongKe = stats['thongKe'] is Map ? stats['thongKe'] : stats;
            _diemChuyenCan = thongKe['diemChuyenCan'] ?? 100;
            _xepLoai = thongKe['xepLoai'] ?? 'A';
            _chuoiDungGio = thongKe['chuoiDungGio'] ?? 0;
          }

          if (history != null) {
            _history = history;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGpsAttendance() async {
    setState(() => _isGettingLocation = true);

    final loc = await _locationService.getCurrentLocation();
    final bool isMock = loc['isMock'] == true;

    if (loc['latitude'] == null || loc['longitude'] == null) {
      if (mounted) {
        setState(() => _isGettingLocation = false);
        _showErrorSnackBar(loc['error'] ?? 'Không lấy được tọa độ GPS. Vui lòng bật định vị.');
      }
      return;
    }

    final lat = loc['latitude'] as double;
    final lng = loc['longitude'] as double;

    setState(() {
      _locationDisplay = 'Tọa độ: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    });

    final res = await _attendanceService.checkIn(
      phuongThuc: 'GPS',
      viDo: lat,
      kinhDo: lng,
      giaLapViTri: isMock,
    );

    if (mounted) {
      setState(() => _isGettingLocation = false);
      if (res['success'] == true) {
        _showSuccessSnackBar(res['message'] ?? 'Chấm công GPS thành công!');
        _loadTodayData();
      } else {
        _showErrorSnackBar(res['message'] ?? 'Chấm công thất bại. Kiểm tra khoảng cách văn phòng.');
      }
    }
  }

  Future<void> _handleQrAttendance() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (scannedCode != null && scannedCode.isNotEmpty) {
      final loc = await _locationService.getCurrentLocation();
      final bool isMock = loc['isMock'] == true;

      final res = await _attendanceService.checkIn(
        phuongThuc: 'QR',
        qrToken: scannedCode,
        viDo: loc['latitude'],
        kinhDo: loc['longitude'],
        giaLapViTri: isMock,
      );

      if (mounted) {
        if (res['success'] == true) {
          _showSuccessSnackBar(res['message'] ?? 'Chấm công qua mã QR thành công!');
          _loadTodayData();
        } else {
          _showErrorSnackBar(res['message'] ?? 'Mã QR không hợp lệ hoặc đã hết hạn.');
        }
      }
    }
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất tài khoản?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await Auth.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, dd/MM/yyyy', 'vi').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fingerprint, color: Color(0xFF1E3A8A), size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Hệ Thống Chấm Công',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
            tooltip: 'Làm mới',
            onPressed: _loadTodayData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTodayData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withAlpha(70),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white,
                                child: Text(
                                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'N',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _userName,
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(40),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _userRole,
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(35),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text('Hạng $_xepLoai', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                    Text(
                                      '$_diemChuyenCan',
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                                  const SizedBox(width: 6),
                                  Text(dateStr, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.bolt, color: Colors.amberAccent, size: 16),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Chuỗi đúng giờ: $_chuoiDungGio ngày',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Today Status Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Ca làm việc hôm nay',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _soPhutTre > 0
                                      ? Colors.red.shade50
                                      : (_daVao ? Colors.green.shade50 : Colors.grey.shade100),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _soPhutTre > 0 ? 'Đi trễ $_soPhutTre phút' : (_daRa ? 'Đã hoàn thành' : (_daVao ? _trangThaiHomNay : 'Chưa vào ca')),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _soPhutTre > 0 ? Colors.red.shade700 : (_daVao ? Colors.green.shade700 : Colors.grey.shade600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.login, size: 16, color: Color(0xFF10B981)),
                                          SizedBox(width: 6),
                                          Text('Giờ vào', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _gioVao,
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.logout, size: 16, color: Color(0xFFEF4444)),
                                          SizedBox(width: 6),
                                          Text('Giờ ra', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _gioRa,
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_locationDisplay.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(_locationDisplay, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Primary Attendance Methods
                    const Text(
                      'Phương thức Chấm công',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),

                    // Method 1: GPS Attendance
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.near_me, color: Color(0xFF2563EB), size: 26),
                        ),
                        title: const Text(
                          'Chấm công Vị trí GPS',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                        subtitle: const Text(
                          'Xác thực trong bán kính Geofence công ty',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        trailing: ElevatedButton(
                          onPressed: _isGettingLocation ? null : _handleGpsAttendance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _daVao ? const Color(0xFFF59E0B) : const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: _isGettingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(_daVao ? 'Ra ca' : 'Vào ca', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),

                    // Method 2: Dynamic QR Attendance
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF9333EA).withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.qr_code_scanner, color: Color(0xFF9333EA), size: 26),
                        ),
                        title: const Text(
                          'Quét mã QR Chấm công',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                        subtitle: const Text(
                          'Quét mã QR động hiển thị tại quầy lễ tân',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        trailing: OutlinedButton.icon(
                          onPressed: _handleQrAttendance,
                          icon: const Icon(Icons.camera_alt, size: 16),
                          label: const Text('Quét', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF9333EA),
                            side: const BorderSide(color: Color(0xFF9333EA)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                      ),
                    ),

                    // Method 3: Motion Sensor Tile
                    Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MotionSensorScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488).withAlpha(20),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.directions_walk, color: Color(0xFF0D9488), size: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Cảm biến Gia tốc & Bước chân',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Trục: X: ${_accelX.toStringAsFixed(1)} | Y: ${_accelY.toStringAsFixed(1)} | Z: ${_accelZ.toStringAsFixed(1)} m/s²',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Quick Utilities
                    const Text(
                      'Tiện ích Công việc',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LeaveManagementScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Color(0xFFEFF6FF),
                                    child: Icon(Icons.event_note, color: Color(0xFF2563EB), size: 22),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Đơn Nghỉ Phép',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Nộp & theo dõi đơn',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SalaryEstimationScreen(
                                    punctualityStreak: _chuoiDungGio,
                                    grade: _xepLoai,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Color(0xFFECFDF5),
                                    child: Icon(Icons.calculate, color: Color(0xFF059669), size: 22),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Bảng Lương & KPI',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Dự báo thu nhập tháng',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Recent History
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lịch sử Gần đây',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          '${_history.length} bản ghi',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_history.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.history, color: Color(0xFFCBD5E1), size: 40),
                            SizedBox(height: 8),
                            Text('Chưa có lịch sử chấm công', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _history.length > 5 ? 5 : _history.length,
                        itemBuilder: (context, idx) {
                          final h = _history[idx];
                          final ngay = h['ngay'] ?? '';
                          final vao = h['gioVao'] != null ? DateFormat('HH:mm').format(DateTime.parse(h['gioVao'])) : '--:--';
                          final ra = h['gioRa'] != null ? DateFormat('HH:mm').format(DateTime.parse(h['gioRa'])) : '--:--';
                          final pt = h['phuongThucVao'] ?? 'GPS';
                          final isLate = (h['soPhutTre'] ?? 0) > 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: pt == 'QR' ? const Color(0xFFF3E8FF) : const Color(0xFFEFF6FF),
                                child: Icon(
                                  pt == 'QR' ? Icons.qr_code : Icons.place,
                                  color: pt == 'QR' ? const Color(0xFF9333EA) : const Color(0xFF2563EB),
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                'Ngày $ngay ($pt)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                              ),
                              subtitle: Text(
                                'Vào: $vao  •  Ra: $ra',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isLate ? Colors.red.shade50 : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isLate ? 'Trễ ${h['soPhutTre']}p' : 'Đúng giờ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isLate ? Colors.red.shade700 : Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
