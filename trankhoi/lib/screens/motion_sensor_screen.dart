import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Màn hình đo chuyển động thực tế bằng cảm biến gia tốc (Accelerometer).
/// Dùng để xác minh nhân viên thực sự di chuyển đến nơi chấm công
/// thay vì giả lập vị trí GPS (mock location).
class MotionSensorScreen extends StatefulWidget {
  const MotionSensorScreen({super.key});

  @override
  State<MotionSensorScreen> createState() => _MotionSensorScreenState();
}

class _MotionSensorScreenState extends State<MotionSensorScreen> {
  // Dữ liệu gia tốc
  double _x = 0, _y = 0, _z = 0;
  double _magnitude = 0;

  // Lịch sử mẫu
  final List<_MotionSample> _samples = [];
  static const int _maxSamples = 200;

  // Trạng thái phát hiện
  String _motionStatus = 'Đang chờ...';
  Color _statusColor = Colors.grey;
  IconData _statusIcon = Icons.hourglass_empty;
  int _stepCount = 0;
  double _peakAccel = 0;

  // Ngưỡng phát hiện bước chân
  static const double _stepThreshold = 12.5; // m/s² (lớn hơn g=9.8)
  static const double _restThreshold = 10.5;
  bool _aboveThreshold = false;
  DateTime? _lastStepTime;

  // Subscription
  StreamSubscription<AccelerometerEvent>? _accelSub;
  Timer? _analysisTimer;

  // Thống kê
  double _avgMagnitude = 0;
  double _maxMagnitude = 0;
  int _movingSeconds = 0;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startListening();
    _startTime = DateTime.now();

    // Phân tích chuyển động mỗi 2 giây
    _analysisTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _analyzeMotion();
    });
  }

  void _startListening() {
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50), // 20Hz
    ).listen((event) {
      setState(() {
        _x = event.x;
        _y = event.y;
        _z = event.z;
        _magnitude = sqrt(_x * _x + _y * _y + _z * _z);

        // Cập nhật peak
        if (_magnitude > _peakAccel) {
          _peakAccel = _magnitude;
        }

        // Phát hiện bước chân (thuật toán đơn giản)
        _detectStep();

        // Lưu mẫu
        _samples.add(_MotionSample(
          time: DateTime.now(),
          x: _x,
          y: _y,
          z: _z,
          magnitude: _magnitude,
        ));
        if (_samples.length > _maxSamples) {
          _samples.removeAt(0);
        }
      });
    });
  }

  void _detectStep() {
    if (_magnitude > _stepThreshold && !_aboveThreshold) {
      _aboveThreshold = true;
      final now = DateTime.now();
      if (_lastStepTime == null ||
          now.difference(_lastStepTime!).inMilliseconds > 250) {
        _stepCount++;
        _lastStepTime = now;
      }
    } else if (_magnitude < _restThreshold) {
      _aboveThreshold = false;
    }
  }

  void _analyzeMotion() {
    if (_samples.isEmpty) return;

    // Tính trung bình và max trong 2 giây gần nhất
    final recent = _samples.where((s) =>
        DateTime.now().difference(s.time).inSeconds < 2).toList();

    if (recent.isEmpty) return;

    double sum = 0;
    double maxVal = 0;
    for (var s in recent) {
      sum += s.magnitude;
      if (s.magnitude > maxVal) maxVal = s.magnitude;
    }
    _avgMagnitude = sum / recent.length;
    if (maxVal > _maxMagnitude) _maxMagnitude = maxVal;

    // Phân loại trạng thái chuyển động
    setState(() {
      if (_avgMagnitude > 15) {
        _motionStatus = 'CHẠY / LẮNG MẠNH';
        _statusColor = Colors.red;
        _statusIcon = Icons.directions_run;
        _movingSeconds += 2;
      } else if (_avgMagnitude > 11.5) {
        _motionStatus = 'ĐANG ĐI BỘ';
        _statusColor = Colors.green;
        _statusIcon = Icons.directions_walk;
        _movingSeconds += 2;
      } else if (_avgMagnitude > 10.2) {
        _motionStatus = 'RUNG NHẸ / CẦM TAY';
        _statusColor = Colors.orange;
        _statusIcon = Icons.vibration;
      } else {
        _motionStatus = 'ĐỨNG YÊN / ĐẶT BÀN';
        _statusColor = Colors.grey;
        _statusIcon = Icons.do_not_disturb;
      }
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _analysisTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    int m = totalSeconds ~/ 60;
    int s = totalSeconds % 60;
    return '${m}p ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Cảm Biến Gia Tốc (3.5đ)'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset',
            onPressed: () {
              setState(() {
                _samples.clear();
                _stepCount = 0;
                _peakAccel = 0;
                _maxMagnitude = 0;
                _movingSeconds = 0;
                _startTime = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Trạng thái chuyển động
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_statusColor.withAlpha(200), _statusColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _statusColor.withAlpha(80),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(_statusIcon, size: 56, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    _motionStatus,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gia tốc: ${_magnitude.toStringAsFixed(1)} m/s²',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Thống kê
            Row(
              children: [
                _buildStatCard('Bước chân', '$_stepCount', Icons.directions_walk, Colors.teal),
                const SizedBox(width: 8),
                _buildStatCard('Peak', _peakAccel.toStringAsFixed(1), Icons.show_chart, Colors.red),
                const SizedBox(width: 8),
                _buildStatCard('Đi bộ', _formatDuration(_movingSeconds), Icons.timer, Colors.green),
                const SizedBox(width: 8),
                _buildStatCard('Thời gian', _formatDuration(elapsed), Icons.access_time, Colors.blue),
              ],
            ),

            const SizedBox(height: 16),

            // Dữ liệu thô XYZ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withAlpha(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dữ liệu Accelerometer (thời gian thực)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildAxisBar('X', _x, Colors.red),
                  const SizedBox(height: 8),
                  _buildAxisBar('Y', _y, Colors.green),
                  const SizedBox(height: 8),
                  _buildAxisBar('Z', _z, Colors.blue),
                  const SizedBox(height: 8),
                  _buildAxisBar('|a|', _magnitude, Colors.purple),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Biểu đồ đơn giản (bar chart từ samples gần nhất)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withAlpha(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đồ thị gia tốc (50 mẫu gần nhất)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: _samples.isEmpty
                        ? const Center(child: Text('Đang thu thập dữ liệu...'))
                        : CustomPaint(
                            size: const Size(double.infinity, 120),
                            painter: _AccelChartPainter(
                              samples: _samples.length > 50
                                  ? _samples.sublist(_samples.length - 50)
                                  : _samples,
                            ),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Giải thích
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Ứng dụng trong chấm công',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Xác minh nhân viên thực sự DI CHUYỂN đến nơi làm việc\n'
                    '• Phát hiện thiết bị đặt yên trên bàn (mock location)\n'
                    '• Đếm bước chân xác nhận hoạt động thể chất\n'
                    '• Phân biệt: đi bộ, chạy, đứng yên, rung lắc\n'
                    '• Kết hợp GPS để chống gian lận chấm công',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
            ),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildAxisBar(String axis, double value, Color color) {
    final normalized = (value.abs() / 20).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(width: 24, child: Text(axis, style: TextStyle(fontWeight: FontWeight.bold, color: color))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: normalized,
              backgroundColor: Colors.grey[200],
              color: color,
              minHeight: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            '${value.toStringAsFixed(2)} m/s²',
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}

/// Mẫu dữ liệu cảm biến
class _MotionSample {
  final DateTime time;
  final double x, y, z, magnitude;
  _MotionSample({required this.time, required this.x, required this.y, required this.z, required this.magnitude});
}

/// Vẽ biểu đồ gia tốc đơn giản
class _AccelChartPainter extends CustomPainter {
  final List<_MotionSample> samples;
  _AccelChartPainter({required this.samples});

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final paintMag = Paint()
      ..color = Colors.deepPurple
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final paintThreshold = Paint()
      ..color = Colors.red.withAlpha(100)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Đường ngưỡng bước chân
    final thresholdY = size.height - (12.5 / 25 * size.height);
    canvas.drawLine(
      Offset(0, thresholdY),
      Offset(size.width, thresholdY),
      paintThreshold,
    );

    // Vẽ đồ thị magnitude
    final path = Path();
    for (int i = 0; i < samples.length; i++) {
      final x = i / (samples.length - 1) * size.width;
      final y = size.height - (samples[i].magnitude / 25 * size.height);
      if (i == 0) {
        path.moveTo(x, y.clamp(0, size.height));
      } else {
        path.lineTo(x, y.clamp(0, size.height));
      }
    }
    canvas.drawPath(path, paintMag);

    // Nền gradient
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.deepPurple.withAlpha(60), Colors.deepPurple.withAlpha(5)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _AccelChartPainter oldDelegate) => true;
}
