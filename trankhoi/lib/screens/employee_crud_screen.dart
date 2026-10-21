import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trankhoi/services/employee_service.dart';

class EmployeeCrudScreen extends StatefulWidget {
  const EmployeeCrudScreen({super.key});

  @override
  State<EmployeeCrudScreen> createState() => _EmployeeCrudScreenState();
}

class _EmployeeCrudScreenState extends State<EmployeeCrudScreen> {
  final EmployeeService _service = EmployeeService();
  bool _isLoading = true;
  List<dynamic> _employees = [];
  List<dynamic> _departments = [];
  List<dynamic> _shifts = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _service.getAll(),
      _service.getDepartments(),
      _service.getShifts(),
    ]);

    setState(() {
      _employees = results[0];
      _departments = results[1];
      _shifts = results[2];
      _isLoading = false;
    });
  }

  Future<void> _refreshList() async {
    final list = await _service.getAll(timKiem: _searchQuery.isNotEmpty ? _searchQuery : null);
    setState(() {
      _employees = list;
    });
  }

  void _showEmployeeForm({Map<String, dynamic>? employee}) {
    final isEditing = employee != null;
    final maNVController = TextEditingController(text: employee?['maNV'] ?? 'NV${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
    final hoTenController = TextEditingController(text: employee?['hoTen'] ?? '');
    final emailController = TextEditingController(text: employee?['email'] ?? '');
    final phoneController = TextEditingController(text: employee?['soDienThoai'] ?? '');
    final chucVuController = TextEditingController(text: employee?['chucVu'] ?? 'Nhân viên');
    final luongController = TextEditingController(text: employee?['luongCoBan']?.toString() ?? '10000000');
    
    int? selectedDeptId = employee?['phongBanId'] ?? (_departments.isNotEmpty ? _departments[0]['id'] : null);
    int? selectedShiftId = employee?['caLamViecId'] ?? (_shifts.isNotEmpty ? _shifts[0]['id'] : null);
    String gioiTinh = employee?['gioiTinh'] ?? 'Nam';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Sửa Nhân Viên (Update)' : 'Thêm Nhân Viên Mới (Create)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: maNVController,
                  decoration: const InputDecoration(labelText: 'Mã nhân viên (bắt buộc)'),
                ),
                TextField(
                  controller: hoTenController,
                  decoration: const InputDecoration(labelText: 'Họ và tên (bắt buộc)'),
                ),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email liên kết'),
                ),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                ),
                TextField(
                  controller: chucVuController,
                  decoration: const InputDecoration(labelText: 'Chức vụ'),
                ),
                TextField(
                  controller: luongController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Lương cơ bản (VNĐ)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: gioiTinh,
                  decoration: const InputDecoration(labelText: 'Giới tính'),
                  items: const [
                    DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                    DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                  ],
                  onChanged: (v) => setDialogState(() => gioiTinh = v ?? 'Nam'),
                ),
                if (_departments.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: selectedDeptId,
                    decoration: const InputDecoration(labelText: 'Phòng ban'),
                    items: _departments.map<DropdownMenuItem<int>>((d) {
                      return DropdownMenuItem<int>(
                        value: d['id'] as int,
                        child: Text(d['ten'].toString()),
                      );
                    }).toList(),
                    onChanged: (v) => setDialogState(() => selectedDeptId = v),
                  ),
                ],
                if (_shifts.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: selectedShiftId,
                    decoration: const InputDecoration(labelText: 'Ca làm việc'),
                    items: _shifts.map<DropdownMenuItem<int>>((s) {
                      return DropdownMenuItem<int>(
                        value: s['id'] as int,
                        child: Text(s['ten'].toString()),
                      );
                    }).toList(),
                    onChanged: (v) => setDialogState(() => selectedShiftId = v),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
              onPressed: () async {
                if (maNVController.text.trim().isEmpty || hoTenController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập Mã NV và Họ tên')),
                  );
                  return;
                }

                final body = {
                  'maNV': maNVController.text.trim(),
                  'hoTen': hoTenController.text.trim(),
                  'email': emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
                  'soDienThoai': phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
                  'chucVu': chucVuController.text.trim(),
                  'luongCoBan': double.tryParse(luongController.text.trim()) ?? 10000000,
                  'gioiTinh': gioiTinh,
                  'ngayVaoLam': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  'dangLamViec': true,
                  'phongBanId': selectedDeptId,
                  'caLamViecId': selectedShiftId,
                };

                final res = isEditing
                    ? await _service.update(employee['id'], body)
                    : await _service.create(body);

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res['message']), backgroundColor: res['success'] ? Colors.green : Colors.red),
                );
                _refreshList();
              },
              child: Text(isEditing ? 'Lưu Sửa' : 'Tạo Mới'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa (Delete)'),
        content: Text('Bạn có chắc chắn muốn xóa nhân viên "$name" khỏi hệ thống không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final res = await _service.delete(id);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res['message']), backgroundColor: res['success'] ? Colors.orange : Colors.red),
              );
              _refreshList();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Quản lý Nhân sự (CRUD - 5.5đ)'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm nhân viên theo tên hoặc mã...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) {
                _searchQuery = val;
                _refreshList();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _employees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 70, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text('Không có dữ liệu nhân viên', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshList,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _employees.length,
                          itemBuilder: (context, index) {
                            final emp = _employees[index];
                            final dept = emp['tenPhongBan'] ?? 'Chưa phân ban';
                            final shift = emp['tenCaLamViec'] ?? 'Chưa phân ca';

                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              elevation: 2,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Text(
                                    emp['hoTen'] != null && emp['hoTen'].toString().isNotEmpty
                                        ? emp['hoTen'][0].toString().toUpperCase()
                                        : 'N',
                                    style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  emp['hoTen'] ?? 'Nhân viên',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Mã NV: ${emp['maNV']} | Chức vụ: ${emp['chucVu'] ?? 'NV'}'),
                                    Text('Phòng ban: $dept | Ca: $shift', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    if (emp['email'] != null)
                                      Text('Email: ${emp['email']}', style: TextStyle(color: Colors.blue[700], fontSize: 12)),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showEmployeeForm(employee: emp),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _confirmDelete(emp['id'], emp['hoTen'] ?? 'Nhân viên'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEmployeeForm(),
        backgroundColor: Colors.blue[900],
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Thêm Nhân Viên', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
