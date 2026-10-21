import 'package:flutter/material.dart';
import 'package:trankhoi/utils/auth.dart';
import 'package:trankhoi/services/attendance_service.dart';
import 'package:trankhoi/screens/login_screen.dart';
import 'package:trankhoi/screens/employee_crud_screen.dart';
import 'package:trankhoi/screens/admin_qr_screen.dart';
import 'package:trankhoi/screens/leave_management_screen.dart';
import 'package:trankhoi/screens/company_config_screen.dart';
import 'package:trankhoi/screens/motion_sensor_screen.dart';
import 'package:trankhoi/screens/salary_estimation_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AttendanceService _service = AttendanceService();
  bool _isLoading = false;
  Map<String, dynamic>? _overview;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    setState(() => _isLoading = true);
    final data = await _service.getOverviewStats();
    if (mounted) {
      setState(() {
        _overview = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    await Auth.logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showAttendanceListModal() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return FutureBuilder<Map<String, dynamic>>(
            future: _service.getAllAttendance(pageSize: 50),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = (snapshot.data?['items'] as List<dynamic>?) ?? [];
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Bảng Chấm Công Toàn Công Ty & Cảnh Báo Gian Lận',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: items.isEmpty
                        ? const Center(child: Text('Chưa có dữ liệu chấm công'))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final bool isSuspicious = item['nghiNgo'] == true;
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                color: isSuspicious ? Colors.red[50] : Colors.white,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isSuspicious ? Colors.red[100] : Colors.blue[100],
                                    child: Icon(
                                      isSuspicious ? Icons.warning : Icons.person,
                                      color: isSuspicious ? Colors.red : Colors.blue[900],
                                    ),
                                  ),
                                  title: Text(
                                    '${item['hoTen']} (${item['maNV']})',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Ngày: ${item['ngay']} | PT: ${item['phuongThucVao'] ?? 'GPS'}'),
                                      if (isSuspicious)
                                        Text('Cảnh báo: ${item['ghiChu'] ?? 'Nghi vấn thiết bị/vị trí'}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  trailing: Text(
                                    item['trangThai'] ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: item['trangThai'] == 'DungGio' ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tongNV = _overview?['tongNhanVien'] ?? 0;
    final diLam = _overview?['coMatHomNay'] ?? _overview?['homNayDiLam'] ?? 0;
    final diTre = _overview?['diTreHomNay'] ?? _overview?['homNayDiTre'] ?? 0;
    final nghiNgo = _overview?['banGhiNghiNgo'] ?? _overview?['homNayNghiNgo'] ?? 0;
    final donNghi = _overview?['donChoDuyet'] ?? _overview?['donNghiChoDuyet'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Trang Quản Trị (Admin Dashboard)'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loadOverview,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOverview,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[900]!, Colors.blue[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.admin_panel_settings, size: 36, color: Colors.blue),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quản Trị Viên Hệ Thống',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Toàn quyền CRUD nhân sự, duyệt đơn và giám sát chống gian lận.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // KPI Summary Cards
              const Text('Chỉ số vận hành hôm nay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildKpiCard('Nhân viên', '$tongNV', Icons.people, Colors.blue),
                  const SizedBox(width: 8),
                  _buildKpiCard('Đang làm', '$diLam', Icons.check_circle, Colors.green),
                  const SizedBox(width: 8),
                  _buildKpiCard('Đi trễ', '$diTre', Icons.access_time, Colors.orange),
                  const SizedBox(width: 8),
                  _buildKpiCard('Nghi vấn', '$nghiNgo', Icons.warning, Colors.red),
                ],
              ),
              const SizedBox(height: 20),

              const Text('Chức năng quản trị', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: [
                  _buildActionCard(
                    title: 'Quản lý Nhân sự (CRUD)',
                    subtitle: 'Thêm, Sửa, Xóa nhân viên (5.5đ)',
                    icon: Icons.people_alt,
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const EmployeeCrudScreen()));
                    },
                  ),
                  _buildActionCard(
                    title: 'Tạo mã QR Động',
                    subtitle: 'Đổi mỗi 60s cho nhân viên quét (3.5đ)',
                    icon: Icons.qr_code,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminQrScreen()));
                    },
                  ),
                  _buildActionCard(
                    title: 'Duyệt Đơn Nghỉ Phép',
                    subtitle: '$donNghi đơn đang chờ phê duyệt',
                    icon: Icons.assignment_turned_in,
                    color: Colors.teal,
                    badge: donNghi > 0 ? '$donNghi' : null,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaveManagementScreen(isAdmin: true)));
                    },
                  ),
                  _buildActionCard(
                    title: 'Bảng Công & Gian Lận',
                    subtitle: 'Phát hiện máy lạ / Mock GPS (1đ)',
                    icon: Icons.verified_user,
                    color: Colors.deepOrange,
                    onTap: _showAttendanceListModal,
                  ),
                  _buildActionCard(
                    title: 'Bảng Lương & KPI Tự Động',
                    subtitle: 'Dự báo lương theo ngày công thực tế',
                    icon: Icons.calculate,
                    color: Colors.cyan,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SalaryEstimationScreen()));
                    },
                  ),
                  _buildActionCard(
                    title: 'Cảm Biến Gia Tốc',
                    subtitle: 'Đo chuyển động, bước chân thực tế',
                    icon: Icons.directions_run,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MotionSensorScreen()),
                      );
                    },
                  ),
                  _buildActionCard(
                    title: 'Cấu hình Danh mục & Vai trò',
                    subtitle: 'Phòng ban • Ca làm • Vị trí • Phân quyền',
                    icon: Icons.settings_suggest,
                    color: Colors.blueGrey,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CompanyConfigScreen()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.grey.withAlpha(25), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 24, color: color),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), maxLines: 1),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
