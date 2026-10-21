import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:trankhoi/services/attendance_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isScanned = false;
  final MobileScannerController _controller = MobileScannerController();
  final AttendanceService _attendanceService = AttendanceService();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showManualInputDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.keyboard, color: Colors.blue),
            SizedBox(width: 8),
            Text('Nhập mã QR thủ công'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dành cho Android Emulator hoặc máy không có camera hướng vào mã QR:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Mã QR Token',
                border: OutlineInputBorder(),
                hintText: 'Dán mã QR tại đây...',
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Lấy mã QR động từ server ngay'),
              onPressed: () async {
                final locs = await _attendanceService.getLocations();
                if (locs.isNotEmpty) {
                  final data = await _attendanceService.getDynamicQr(locs[0]['id']);
                  if (data != null && data['qrToken'] != null) {
                    textController.text = data['qrToken'];
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final code = textController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context); // đóng dialog
                Navigator.pop(context, code); // trả mã về màn hình chính
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã QR Chấm Công'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.edit_note),
            label: const Text('Nhập mã'),
            onPressed: _showManualInputDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() {
                    _isScanned = true;
                  });
                  final String code = barcode.rawValue!;
                  Navigator.pop(context, code);
                  break;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 4),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                const Text(
                  'Đưa mã QR chấm công vào khung hình',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    backgroundColor: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.flash_auto),
                  label: const Text('Chế độ Test: Lấy mã QR từ server'),
                  onPressed: () async {
                    final locs = await _attendanceService.getLocations();
                    if (locs.isNotEmpty) {
                      final data = await _attendanceService.getDynamicQr(locs[0]['id']);
                      if (data != null && data['qrToken'] != null && context.mounted) {
                        Navigator.pop(context, data['qrToken']);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
