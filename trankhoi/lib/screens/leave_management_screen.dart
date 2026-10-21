import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trankhoi/services/leave_service.dart';

class LeaveManagementScreen extends StatefulWidget {
  final bool isAdmin;

  const LeaveManagementScreen({super.key, this.isAdmin = false});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  final LeaveService _leaveService = LeaveService();
  bool _isLoading = true;
  List<dynamic> _leaves = [];

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  Future<void> _loadLeaves() async {
    setState(() => _isLoading = true);
    final data = widget.isAdmin
        ? await _leaveService.getAllLeaves()
        : await _leaveService.getMyLeaves();

    setState(() {
      _leaves = data;
      _isLoading = false;
    });
  }

  void _showCreateLeaveDialog() {
    DateTime tuNgay = DateTime.now();
    DateTime denNgay = DateTime.now().add(const Duration(days: 1));
    final TextEditingController lyDoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tạo Đơn Xin Nghỉ Phép'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Từ ngày:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_dateFormat.format(tuNgay)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tuNgay,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        tuNgay = picked;
                        if (denNgay.isBefore(tuNgay)) denNgay = tuNgay;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                const Text('Đến ngày:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_dateFormat.format(denNgay)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: denNgay,
                      firstDate: tuNgay,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => denNgay = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                const Text('Lý do nghỉ:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(
                  controller: lyDoController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Nhập lý do xin nghỉ phép (nghỉ ốm, việc gia đình...)',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (lyDoController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập lý do nghỉ phép')),
                  );
                  return;
                }

                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                final res = await _leaveService.createLeave(
                  tuNgay: _apiDateFormat.format(tuNgay),
                  denNgay: _apiDateFormat.format(denNgay),
                  lyDo: lyDoController.text.trim(),
                );

                if (!mounted) return;
                nav.pop();

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(res['message']),
                    backgroundColor: res['success'] ? Colors.green : Colors.red,
                  ),
                );
                _loadLeaves();
              },
              child: const Text('Gửi Đơn'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewDialog(int leaveId, String hoTen, String lyDo) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Duyệt Đơn Nghỉ Phép'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nhân viên: $hoTen', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Lý do: $lyDo'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Ghi chú phê duyệt (tùy chọn)'),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              final nav = Navigator.of(dialogCtx);
              final messenger = ScaffoldMessenger.of(context);
              final res = await _leaveService.reviewLeave(leaveId, approve: false, note: noteController.text);
              if (!mounted) return;
              nav.pop();
              _loadLeaves();
              messenger.showSnackBar(SnackBar(content: Text(res['message'])));
            },
            child: const Text('Từ Chối'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              final nav = Navigator.of(dialogCtx);
              final messenger = ScaffoldMessenger.of(context);
              final res = await _leaveService.reviewLeave(leaveId, approve: true, note: noteController.text);
              if (!mounted) return;
              nav.pop();
              _loadLeaves();
              messenger.showSnackBar(SnackBar(content: Text(res['message'])));
            },
            child: const Text('Đồng Ý Duyệt'),
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
        title: Text(widget.isAdmin ? 'Duyệt Đơn Nghỉ Phép (Quản trị)' : 'Đơn Nghỉ Phép Của Tôi'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _leaves.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_note, size: 70, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      const Text('Chưa có đơn nghỉ phép nào', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLeaves,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _leaves.length,
                    itemBuilder: (context, index) {
                      final item = _leaves[index];
                      final status = item['trangThai'] ?? 'ChoDuyet';
                      final bool isApproved = status == 'DaDuyet';
                      final bool isRejected = status == 'TuChoi';

                      Color statusColor = Colors.orange;
                      String statusText = 'Chờ duyệt';
                      if (isApproved) {
                        statusColor = Colors.green;
                        statusText = 'Đã duyệt';
                      } else if (isRejected) {
                        statusColor = Colors.red;
                        statusText = 'Bị từ chối';
                      }

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    widget.isAdmin ? (item['hoTen'] ?? 'Nhân viên') : 'Đơn nghỉ phép',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withAlpha(30),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: statusColor),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.date_range, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Từ: ${item['tuNgay']}  →  Đến: ${item['denNgay']}',
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Lý do: ${item['lyDo'] ?? 'Không ghi'}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                              if (item['ghiChuDuyet'] != null && item['ghiChuDuyet'].toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('Ghi chú duyệt: ${item['ghiChuDuyet']}', style: const TextStyle(color: Colors.blue, fontSize: 12, fontStyle: FontStyle.italic)),
                              ],
                              if (widget.isAdmin && status == 'ChoDuyet') ...[
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.rate_review, size: 16),
                                    label: const Text('Xem & Duyệt'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
                                    onPressed: () => _showReviewDialog(item['id'], item['hoTen'] ?? 'Nhân viên', item['lyDo'] ?? ''),
                                  ),
                                ),
                              ],
                              if (!widget.isAdmin && status == 'ChoDuyet') ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                                    label: const Text('Hủy đơn', style: TextStyle(color: Colors.red)),
                                    onPressed: () async {
                                      final res = await _leaveService.cancelLeave(item['id']);
                                      _loadLeaves();
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: widget.isAdmin
          ? null
          : FloatingActionButton.extended(
              onPressed: _showCreateLeaveDialog,
              backgroundColor: Colors.blue[800],
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Tạo Đơn Nghỉ Phép', style: TextStyle(color: Colors.white)),
            ),
    );
  }
}
