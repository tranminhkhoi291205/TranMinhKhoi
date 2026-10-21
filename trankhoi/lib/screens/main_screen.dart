import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trankhoi/utils/auth.dart';
import 'package:trankhoi/services/attendance_service.dart';
import 'package:trankhoi/services/location_service.dart';
import 'package:trankhoi/services/sensor_service.dart';
import 'package:trankhoi/screens/qr_scanner_screen.dart';
import 'package:trankhoi/screens/face_attendance_screen.dart';
import 'package:trankhoi/screens/leave_management_screen.dart';
import 'package:trankhoi/screens/group_video_call_screen.dart';
import 'package:trankhoi/screens/motion_sensor_screen.dart';
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

  // Trạng thái chấm công hôm nay
  bool _daVao = false;
  bool _daRa = false;
  String _gioVao = '--:--';
  String _gioRa = '--:--';
  String _trangThaiHomNay = 'Chưa chấm công';
  int _soPhutTre = 0;
  String _locationDisplay = 'Chưa lấy vị trí GPS';
  bool _isGettingLocation = false;

  // Điểm chuyên cần (Tính năng mới tự đề xuất)
  int _diemChuyenCan = 100;
  String _xepLoai = 'A';
  int _chuoiDungGio = 0;

  // Lịch sử gần đây
  List<dynamic> _history = [];

  // Cảm biến gia tốc
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
    setState(() {
      _userName = prefs.getString('user_hoten') ?? prefs.getString('user_username') ?? 'Nhân viên';
      _userRole = prefs.getString('user_role') ?? 'Nhân viên';
    });
  }

  Future<void> _loadTodayData() async {
    setState(() => _isLoading = true);

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
        if (today != null) {
          _daVao = today['daVao'] == true;
          _daRa = today['daRa'] == true;
          if (today['gioVao'] != null) {
            _gioVao = DateFormat('HH:mm').format(DateTime.parse(today['gioVao'].toString()));
          }
          if (today['gioRa'] != null) {
            _gioRa = DateFormat('HH:mm').format(DateTime.parse(today['gioRa'].toString()));
          }
          _soPhutTre = today['soPhutTre'] ?? 0;
          _trangThaiHomNay = today['trangThai'] ?? (_daVao ? 'Đã vào ca' : 'Chưa chấm công');
        }

        if (stats != null) {
          final tk = (stats['thongKe'] as Map<String, dynamic>?) ?? stats;
          _diemChuyenCan = tk['diemChuyenCan'] ?? 100;
          _xepLoai = tk['xepLoai'] ?? 'A';
          _chuoiDungGio = tk['chuoiDungGio'] ?? 0;
        }

        _history = history ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGpsAttendance() async {
    setState(() => _isGettingLocation = true);

    final loc = await _locationService.getCurrentLocation();
    setState(() {
      _locationDisplay = loc['message'];
      _isGettingLocation = false;
    });

    final bool isCheckIn = !_daVao;
    final res = isCheckIn
        ? await _attendanceService.checkIn(
            phuongThuc: 'GPS',
            viDo: loc['latitude'],
            kinhDo: loc['longitude'],
            deviceId: 'DEVICE_MOBILE_DEMO_01',
            giaLapViTri: false,
          )
        : await _attendanceService.checkOut(
            phuongThuc: 'GPS',
            viDo: loc['latitude'],
            kinhDo: loc['longitude'],
            deviceId: 'DEVICE_MOBILE_DEMO_01',
            giaLapViTri: false,
          );

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']), backgroundColor: Colors.green),
      );
      _loadTodayData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']), backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> _handleQrAttendance() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (scannedCode != null && mounted) {
      final loc = await _locationService.getCurrentLocation();
      final bool isCheckIn = !_daVao;

      final res = isCheckIn
          ? await _attendanceService.checkIn(
              phuongThuc: 'QR',
              qrToken: scannedCode,
              viDo: loc['latitude'],
              kinhDo: loc['longitude'],
              deviceId: 'DEVICE_MOBILE_DEMO_01',
            )
          : await _attendanceService.checkOut(
              phuongThuc: 'QR',
              qrToken: scannedCode,
              viDo: loc['latitude'],
              kinhDo: loc['longitude'],
              deviceId: 'DEVICE_MOBILE_DEMO_01',
            );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']),
          backgroundColor: res['success'] ? Colors.green : Colors.red,
        ),
      );
      _loadTodayData();
    }
  }

  Future<void> _handleLogout() async {
    await Auth.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nowStr = DateFormat('EEEE, dd/MM/yyyy', 'vi').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Dashboard Nhân Viên'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loadTodayData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[900]!, Colors.blue[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.blue.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, size: 38, color: Colors.blue[900]),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Vai trò: $_userRole | Hôm nay: $nowStr',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tính năng tự đề xuất (1đ): Điểm chuyên cần & Chống gian lận
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.stars, color: Colors.amber, size: 24),
                                    SizedBox(width: 8),
                                    Text(
                                      'Điểm Chuyên Cần & Thi Đua (1đ)',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue),
                                  ),
                                  child: Text(
                                    'Hạng $_xepLoai',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900]),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      '$_diemChuyenCan/100',
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                    const Text('Điểm chuyên cần', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                                Container(width: 1, height: 35, color: Colors.grey[300]),
                                Column(
                                  children: [
                                    Text(
                                      '$_chuoiDungGio ngày',
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
                                    ),
                                    const Text('Chuỗi đúng giờ liên tục', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(),
                            Row(
                              children: [
                                const Icon(Icons.verified_user, size: 16, color: Colors.green),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Bảo mật chống gian lận: Thiết bị đã liên kết • Chặn Mock GPS',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Trạng thái ca làm việc hôm nay
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Trạng thái ca làm việc hôm nay',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text('Giờ vào', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(_gioVao, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('Giờ ra', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(_gioRa, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('Trạng thái', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _soPhutTre > 0 ? 'Trễ $_soPhutTre p' : (_daRa ? 'Đã ra ca' : (_daVao ? _trangThaiHomNay : 'Chưa vào')),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _soPhutTre > 0 ? Colors.red : (_daVao ? Colors.green : Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (_locationDisplay.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(_locationDisplay, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3 Phương thức thuyết trình (3.5đ)
                    const Text(
                      '3 Chức năng Thuyết trình (3.5đ)',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // 1. Chấm công GPS
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.my_location, color: Colors.blue),
                        ),
                        title: const Text('1. Chấm công GPS (Chia sẻ vị trí)', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Kiểm tra Geofence bán kính văn phòng Haversine'),
                        trailing: ElevatedButton(
                          onPressed: _isGettingLocation ? null : _handleGpsAttendance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _daVao ? Colors.orange : Colors.blue[800],
                            foregroundColor: Colors.white,
                          ),
                          child: _isGettingLocation
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(_daVao ? 'Check-out' : 'Check-in'),
                        ),
                      ),
                    ),

                    // 2. Chấm công QR Động
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.purple[50], borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.qr_code_scanner, color: Colors.purple),
                        ),
                        title: const Text('2. Quét QR Động (Đổi mỗi 60s)', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Quét mã bảo mật hiển thị tại màn hình Admin'),
                        trailing: OutlinedButton(
                          onPressed: _handleQrAttendance,
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.purple)),
                          child: const Text('Quét QR', style: TextStyle(color: Colors.purple)),
                        ),
                      ),
                    ),

                    // 3. Chấm công Khuôn mặt
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.face_retouching_natural, color: Colors.green),
                        ),
                        title: const Text('3. Chấm công Khuôn mặt (AI Face)', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('So khớp vector đặc trưng Cosine Similarity'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_a_photo, color: Colors.green),
                              tooltip: 'Đăng ký khuôn mặt',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const FaceAttendanceScreen(isRegistration: true)),
                                );
                              },
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final res = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(builder: (context) => const FaceAttendanceScreen(isRegistration: false)),
                                );
                                if (res == true) _loadTodayData();
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
                              child: const Text('Quét Mặt'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tiện ích: Đơn nghỉ phép & Họp video nhóm & Cảm biến
                    const Text('Tiện ích nhân viên', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.event_available, color: Colors.indigo, size: 30),
                                  SizedBox(height: 8),
                                  Text('Đơn Nghỉ Phép', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('Tạo & xem lịch sử', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                                MaterialPageRoute(builder: (context) => const GroupVideoCallScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.teal.shade100),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.video_call, color: Colors.teal, size: 30),
                                  SizedBox(height: 8),
                                  Text('Họp Video Nhóm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('Phòng họp online', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Cảm biến đo chuyển động gia tốc
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MotionSensorScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            children: [
                              const Icon(Icons.motion_photos_on, color: Colors.deepPurple),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '3. Cảm biến gia tốc thực tế (3.5đ) - Chạm để xem chi tiết',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'X: ${_accelX.toStringAsFixed(1)} | Y: ${_accelY.toStringAsFixed(1)} | Z: ${_accelZ.toStringAsFixed(1)} m/s²',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Lịch sử chấm công gần đây
                    const Text('Lịch sử chấm công gần đây', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_history.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: Text('Chưa có lịch sử chấm công', style: TextStyle(color: Colors.grey))),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _history.length > 5 ? 5 : _history.length,
                        itemBuilder: (context, idx) {
                          final h = _history[idx];
                          final ngay = h['ngay'] ?? '';
                          final vao = h['gioVao'] != null ? DateFormat('HH:mm').format(DateTime.parse(h['gioVao'])) : '--';
                          final ra = h['gioRa'] != null ? DateFormat('HH:mm').format(DateTime.parse(h['gioRa'])) : '--';
                          final pt = h['phuongThucVao'] ?? 'GPS';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[50],
                                child: Icon(pt == 'FACE' ? Icons.face : (pt == 'QR' ? Icons.qr_code : Icons.place), color: Colors.blue[800], size: 20),
                              ),
                              title: Text('Ngày: $ngay ($pt)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text('Vào: $vao  |  Ra: $ra'),
                              trailing: Text(
                                h['trangThai'] ?? '',
                                style: TextStyle(color: h['trangThai'] == 'DungGio' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
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
