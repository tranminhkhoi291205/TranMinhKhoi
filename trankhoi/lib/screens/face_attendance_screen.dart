import 'package:flutter/material.dart';
import 'package:trankhoi/services/attendance_service.dart';
import 'package:trankhoi/services/employee_service.dart';
import 'package:trankhoi/services/face_service.dart';
import 'package:trankhoi/services/location_service.dart';

class FaceAttendanceScreen extends StatefulWidget {
  final bool isRegistration;

  const FaceAttendanceScreen({super.key, this.isRegistration = false});

  @override
  State<FaceAttendanceScreen> createState() => _FaceAttendanceScreenState();
}

class _FaceAttendanceScreenState extends State<FaceAttendanceScreen> with SingleTickerProviderStateMixin {
  final EmployeeService _employeeService = EmployeeService();
  final AttendanceService _attendanceService = AttendanceService();
  final LocationService _locationService = LocationService();

  late AnimationController _animController;
  bool _isProcessing = false;
  String _statusMessage = 'Đang nhận diện khuôn mặt...';
  double _similarity = 0.0;
  final bool _faceDetected = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _statusMessage = widget.isRegistration
        ? 'Giữ khuôn mặt trong khung hình tròn để đăng ký mẫu sinh trắc học'
        : 'Hướng khuôn mặt về camera để chấm công AI Face Recognition';
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleFaceAction() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Đang trích xuất đặc trưng vector 128 chiều...';
    });

    await Future.delayed(const Duration(milliseconds: 900));

    // Lấy vector đã đăng ký hoặc tạo vector mẫu
    List<double>? registeredVector = await FaceService.getLocalVector();

    if (widget.isRegistration) {
      // Đăng ký khuôn mặt mới
      final newVector = FaceService.generateFaceVector(seed: 'trankhoi_user', noiseLevel: 0.0);
      final res = await _employeeService.registerFace(newVector);

      await FaceService.saveLocalVector(newVector);

      setState(() {
        _isProcessing = false;
        _similarity = 1.0;
      });

      if (!mounted) return;
      if (res['success'] == true) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Đăng ký thành công'),
              ],
            ),
            content: const Text('Mẫu khuôn mặt AI đã được đồng bộ lên máy chủ SQL Server thành công!'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text('Xong'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']), backgroundColor: Colors.red),
        );
      }
    } else {
      // Chấm công bằng khuôn mặt
      registeredVector ??= FaceService.generateFaceVector(seed: 'trankhoi_user', noiseLevel: 0.0);
      // Tạo vector nhận diện thực tế với độ tương đồng ~ 95%
      final currentScanVector = FaceService.generateFaceVector(seed: 'trankhoi_user', noiseLevel: 0.08);

      final similarity = FaceService.cosineSimilarity(registeredVector, currentScanVector);
      setState(() {
        _similarity = similarity;
        _statusMessage = 'Độ tương đồng Cosine: ${(similarity * 100).toStringAsFixed(1)}%';
      });

      // Lấy GPS đồng thời (yêu cầu từ CSDL backend)
      final loc = await _locationService.getCurrentLocation();

      final res = await _attendanceService.checkIn(
        phuongThuc: 'FACE',
        viDo: loc['latitude'],
        kinhDo: loc['longitude'],
        khuonMat: currentScanVector,
        deviceId: 'DEVICE_MOBILE_DEMO_01',
        giaLapViTri: false,
      );

      setState(() => _isProcessing = false);

      if (!mounted) return;

      if (res['success'] == true) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.verified, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('Chấm công thành công!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(res['message']),
                const SizedBox(height: 8),
                Text('Phương thức: Khuôn mặt (Face Recognition)'),
                Text('Độ khớp khuôn mặt: ${(similarity * 100).toStringAsFixed(1)}%'),
                Text('Toạ độ: ${loc['latitude']}, ${loc['longitude']}'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']), backgroundColor: Colors.orange),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.isRegistration ? 'Đăng Ký Khuôn Mặt' : 'Chấm Công Khuôn Mặt'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            const Spacer(),
            // Face Camera Simulation Frame
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _faceDetected ? Colors.greenAccent : Colors.redAccent,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_faceDetected ? Colors.greenAccent : Colors.blueAccent).withAlpha(60),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                      gradient: RadialGradient(
                        colors: [Colors.grey[900]!, Colors.black],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.face_retouching_natural,
                        size: 140,
                        color: Colors.white.withAlpha(200),
                      ),
                    ),
                  ),
                  // Animated Scanning Line
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return Positioned(
                        top: 20 + (_animController.value * 240),
                        child: Container(
                          width: 260,
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.greenAccent, Colors.transparent],
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.greenAccent, blurRadius: 8),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (_similarity > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _similarity,
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cosine Similarity: ${(_similarity * 100).toStringAsFixed(1)}% (Ngưỡng yêu cầu: 80%)',
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 13),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _handleFaceAction,
                  icon: _isProcessing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(widget.isRegistration ? Icons.camera_alt : Icons.face),
                  label: Text(
                    widget.isRegistration ? 'Chụp & Đăng ký khuôn mặt' : 'Quét khuôn mặt Chấm công',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
