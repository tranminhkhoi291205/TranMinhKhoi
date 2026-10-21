import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:trankhoi/screens/login_screen.dart';
import 'package:trankhoi/services/location_service.dart';
import 'package:trankhoi/utils/auth.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final LocationService _locationService = LocationService();
  String _customerName = 'Khách Hàng / Đối Tác';
  bool _isCheckedIn = false;
  String _checkInTime = '';
  String _visitorPassId = '';
  String _locationInfo = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final me = await Auth.getMe();
    if (me != null && mounted) {
      setState(() {
        _customerName = me['hoTen'] ?? me['username'] ?? 'Khách Hàng';
      });
    }
  }

  Future<void> _handleVisitorCheckIn() async {
    final loc = await _locationService.getCurrentLocation();
    setState(() {
      _isCheckedIn = true;
      _checkInTime = TimeOfDay.now().format(context);
      _visitorPassId = 'VISITOR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      _locationInfo = '${loc['latitude']}, ${loc['longitude']}';
    });

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Check-in Khách Thành Công!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chào mừng $_customerName đến làm việc tại Văn phòng chính HUTECH.'),
            const SizedBox(height: 8),
            Text('Mã thẻ khách: $_visitorPassId', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Thời gian: $_checkInTime'),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 130,
                height: 130,
                child: QrImageView(
                  data: 'VISITOR_PASS:$_visitorPassId',
                  version: QrVersions.auto,
                  size: 130.0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Xuất trình mã này tại quầy lễ tân hoặc bàn bảo vệ cổng A.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Cổng Thông Tin Khách Hàng'),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal[800]!, Colors.teal[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.teal.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.business_center, size: 36, color: Colors.teal),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _customerName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Khách Hàng / Đối tác doanh nghiệp',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Visitor Pass / Check-in Card
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
                            Icon(Icons.badge, color: Colors.teal, size: 24),
                            SizedBox(width: 8),
                            Text('Thẻ Khách Thăm Quan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isCheckedIn ? Colors.green[50] : Colors.amber[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _isCheckedIn ? Colors.green : Colors.amber),
                          ),
                          child: Text(
                            _isCheckedIn ? 'Đã Vào Tòa Nhà' : 'Chưa Check-in',
                            style: TextStyle(
                              color: _isCheckedIn ? Colors.green[800] : Colors.orange[900],
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _isCheckedIn
                          ? 'Mã thẻ: $_visitorPassId | Vào lúc: $_checkInTime\nVị trí GPS: $_locationInfo'
                          : 'Bấm nút bên dưới để đăng ký nhận thẻ khách và check-in vào văn phòng làm việc.',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCheckedIn ? Colors.green[700] : Colors.teal[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _handleVisitorCheckIn,
                        icon: Icon(_isCheckedIn ? Icons.verified : Icons.qr_code_scanner),
                        label: Text(_isCheckedIn ? 'Cập Nhật Lại Thẻ Khách' : 'Check-in Khách Tham Quan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Thông tin văn phòng
            const Text('Thông Tin Văn Phòng & Trụ Sở', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.red),
                    title: const Text('Trụ sở chính (HUTECH Campus)'),
                    subtitle: const Text('475A Điện Biên Phủ, P.25, Q.Bình Thạnh, TP.HCM'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.access_time, color: Colors.blue),
                    title: const Text('Thời gian tiếp khách'),
                    subtitle: const Text('Thứ 2 - Thứ 6: 08:00 - 17:00 (Nghỉ trưa: 12:00 - 13:00)'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.phone, color: Colors.green),
                    title: const Text('Hotline / Lễ tân'),
                    subtitle: const Text('(028) 5445 7777 - Nhánh 101'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.support_agent, color: Colors.purple),
                    title: const Text('Phòng Kỹ thuật & Hỗ trợ phần mềm'),
                    subtitle: const Text('Khu văn phòng E1 - Tầng 3'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
