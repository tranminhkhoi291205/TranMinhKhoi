import 'package:flutter/material.dart';
import 'package:trankhoi/services/company_service.dart';
import 'package:trankhoi/services/location_service.dart';

class CompanyConfigScreen extends StatefulWidget {
  final int initialTab;
  const CompanyConfigScreen({super.key, this.initialTab = 0});

  @override
  State<CompanyConfigScreen> createState() => _CompanyConfigScreenState();
}

class _CompanyConfigScreenState extends State<CompanyConfigScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CompanyService _service = CompanyService();

  bool _isLoading = true;
  List<dynamic> _departments = [];
  List<dynamic> _shifts = [];
  List<dynamic> _locations = [];
  List<dynamic> _accounts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _service.getDepartments(),
      _service.getShifts(),
      _service.getLocations(),
      _service.getAccounts(),
    ]);

    if (mounted) {
      setState(() {
        _departments = results[0];
        _shifts = results[1];
        _locations = results[2];
        _accounts = results[3];
        _isLoading = false;
      });
    }
  }

  // ================= DIALOGS CHO PHÒNG BAN =================
  void _showDepartmentDialog({Map<String, dynamic>? dept}) {
    final isEdit = dept != null;
    final nameController = TextEditingController(text: dept?['ten'] ?? '');
    final descController = TextEditingController(text: dept?['moTa'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Sửa Phòng Ban' : 'Thêm Phòng Ban Mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên phòng ban *')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Mô tả nhiệm vụ')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              final res = isEdit
                  ? await _service.updateDepartment(dept['id'], nameController.text, descController.text)
                  : await _service.createDepartment(nameController.text, descController.text);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
              _loadAllData();
            },
            child: Text(isEdit ? 'Lưu' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  // ================= DIALOGS CHO CA LÀM VIỆC =================
  void _showShiftDialog({Map<String, dynamic>? shift}) {
    final isEdit = shift != null;
    final nameController = TextEditingController(text: shift?['ten'] ?? 'Ca sáng');
    final startController = TextEditingController(text: shift?['gioBatDau'] ?? '08:00');
    final endController = TextEditingController(text: shift?['gioKetThuc'] ?? '17:00');
    final lateController = TextEditingController(text: (shift?['phutChoPhepTre'] ?? 10).toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Sửa Ca Làm Việc' : 'Thêm Ca Làm Việc Mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên ca *')),
              TextField(controller: startController, decoration: const InputDecoration(labelText: 'Giờ bắt đầu (HH:mm) *')),
              TextField(controller: endController, decoration: const InputDecoration(labelText: 'Giờ kết thúc (HH:mm) *')),
              TextField(controller: lateController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Phút cho phép trễ')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final phut = int.tryParse(lateController.text) ?? 10;
              final res = isEdit
                  ? await _service.updateShift(shift['id'], ten: nameController.text, gioBatDau: startController.text, gioKetThuc: endController.text, phutChoPhepTre: phut)
                  : await _service.createShift(ten: nameController.text, gioBatDau: startController.text, gioKetThuc: endController.text, phutChoPhepTre: phut);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
              _loadAllData();
            },
            child: Text(isEdit ? 'Lưu' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  // ================= DIALOGS CHO VỊ TRÍ CHẤM CÔNG =================
  void _showLocationDialog({Map<String, dynamic>? loc}) {
    final isEdit = loc != null;
    final nameController = TextEditingController(text: loc?['ten'] ?? 'Văn phòng chính');
    final addrController = TextEditingController(text: loc?['diaChi'] ?? '475A Điện Biên Phủ, HUTECH');
    final latController = TextEditingController(text: (loc?['latitude'] ?? 10.8018).toString());
    final lngController = TextEditingController(text: (loc?['longitude'] ?? 106.7143).toString());
    final radiusController = TextEditingController(text: (loc?['banKinhMet'] ?? 150).toString());
    final LocationService locationService = LocationService();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Sửa Vị Trí Chấm Công' : 'Thêm Vị Trí Chấm Công'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên vị trí *')),
                TextField(controller: addrController, decoration: const InputDecoration(labelText: 'Địa chỉ')),
                TextField(controller: latController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Vĩ độ (Latitude) *')),
                TextField(controller: lngController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Kinh độ (Longitude) *')),
                TextField(controller: radiusController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Bán kính Geofence (Mét) *')),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.my_location, color: Colors.blue),
                    label: const Text('Lấy tọa độ vị trí hiện tại của tôi'),
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đang lấy vị trí GPS hiện tại...'), duration: Duration(seconds: 1)),
                      );
                      final pos = await locationService.getCurrentLocation();
                      if (pos['latitude'] != null && pos['longitude'] != null) {
                        setDialogState(() {
                          latController.text = pos['latitude'].toString();
                          lngController.text = pos['longitude'].toString();
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Đã cập nhật tọa độ: ${pos['latitude']}, ${pos['longitude']}')),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final lat = double.tryParse(latController.text) ?? 10.8018;
                final lng = double.tryParse(lngController.text) ?? 106.7143;
                final r = int.tryParse(radiusController.text) ?? 150;
                final res = isEdit
                    ? await _service.updateLocation(loc['id'], ten: nameController.text, diaChi: addrController.text, latitude: lat, longitude: lng, banKinhMet: r)
                    : await _service.createLocation(ten: nameController.text, diaChi: addrController.text, latitude: lat, longitude: lng, banKinhMet: r);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
                _loadAllData();
              },
              child: Text(isEdit ? 'Lưu' : 'Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  // ================= DIALOG PHÂN QUYỀN TÀI KHOẢN =================
  void _showRoleDialog(Map<String, dynamic> acc) {
    String currentRole = acc['role'] ?? 'NhanVien';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Phân Quyền: ${acc['userName']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Họ tên: ${acc['hoTen']}'),
              Text('Email: ${acc['email']}'),
              const SizedBox(height: 12),
              const Text('Chọn vai trò mới:', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: currentRole,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Admin', child: Text('Admin (Quản trị viên)')),
                  DropdownMenuItem(value: 'QuanLy', child: Text('QuanLy (Quản lý bộ phận)')),
                  DropdownMenuItem(value: 'NhanVien', child: Text('NhanVien (Nhân viên)')),
                  DropdownMenuItem(value: 'KhachHang', child: Text('KhachHang (Khách hàng)')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => currentRole = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final res = await _service.updateRole(acc['id'], currentRole);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
                _loadAllData();
              },
              child: const Text('Cập nhật vai trò'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Trị Hệ Thống (CRUD 5.5đ)'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(icon: Icon(Icons.corporate_fare), text: 'Phòng ban'),
            Tab(icon: Icon(Icons.schedule), text: 'Ca làm'),
            Tab(icon: Icon(Icons.pin_drop), text: 'Vị trí GPS'),
            Tab(icon: Icon(Icons.manage_accounts), text: 'Tài khoản'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // 1. Tab Phòng ban
                _buildDepartmentTab(),
                // 2. Tab Ca làm việc
                _buildShiftTab(),
                // 3. Tab Vị trí chấm công
                _buildLocationTab(),
                // 4. Tab Tài khoản & Phân quyền
                _buildAccountTab(),
              ],
            ),
    );
  }

  Widget _buildDepartmentTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        onPressed: () => _showDepartmentDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm Phòng Ban'),
      ),
      body: _departments.isEmpty
          ? const Center(child: Text('Chưa có phòng ban nào'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 8),
              itemCount: _departments.length,
              itemBuilder: (context, index) {
                final d = _departments[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[50],
                      child: const Icon(Icons.domain, color: Colors.blue),
                    ),
                    title: Text(d['ten'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${d['moTa'] ?? 'Không có mô tả'} • Số nhân sự: ${d['soNhanVien'] ?? 0}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showDepartmentDialog(dept: d),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final res = await _service.deleteDepartment(d['id']);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
                            _loadAllData();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildShiftTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo[800],
        foregroundColor: Colors.white,
        onPressed: () => _showShiftDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm Ca Làm'),
      ),
      body: _shifts.isEmpty
          ? const Center(child: Text('Chưa có ca làm việc nào'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 8),
              itemCount: _shifts.length,
              itemBuilder: (context, index) {
                final s = _shifts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo[50],
                      child: const Icon(Icons.access_time_filled, color: Colors.indigo),
                    ),
                    title: Text(s['ten'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Giờ: ${s['gioBatDau']} - ${s['gioKetThuc']} | Trễ tối đa: ${s['phutChoPhepTre']} phút'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showShiftDialog(shift: s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final res = await _service.deleteShift(s['id']);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
                            _loadAllData();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildLocationTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
        onPressed: () => _showLocationDialog(),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Thêm Điểm Chấm Công'),
      ),
      body: _locations.isEmpty
          ? const Center(child: Text('Chưa có vị trí chấm công nào'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 8),
              itemCount: _locations.length,
              itemBuilder: (context, index) {
                final loc = _locations[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal[50],
                      child: const Icon(Icons.location_on, color: Colors.teal),
                    ),
                    title: Text(loc['ten'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Toạ độ: ${loc['latitude']}, ${loc['longitude']} • Bán kính: ${loc['banKinhMet']}m\n${loc['diaChi'] ?? ''}'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showLocationDialog(loc: loc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final res = await _service.deleteLocation(loc['id']);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
                            _loadAllData();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAccountTab() {
    return _accounts.isEmpty
        ? const Center(child: Text('Chưa có tài khoản nào'))
        : ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _accounts.length,
            itemBuilder: (context, index) {
              final a = _accounts[index];
              final role = a['role'] ?? 'NhanVien';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: role == 'Admin' ? Colors.red[50] : (role == 'QuanLy' ? Colors.orange[50] : Colors.blue[50]),
                    child: Icon(
                      role == 'Admin' ? Icons.security : (role == 'QuanLy' ? Icons.manage_accounts : Icons.person),
                      color: role == 'Admin' ? Colors.red : (role == 'QuanLy' ? Colors.orange : Colors.blue),
                    ),
                  ),
                  title: Text('${a['hoTen']} (${a['userName']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Email: ${a['email']} • Vai trò: $role'),
                  trailing: OutlinedButton(
                    onPressed: () => _showRoleDialog(a),
                    child: const Text('Phân quyền'),
                  ),
                ),
              );
            },
          );
  }
}
