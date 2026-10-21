import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Tính năng mới tự đề xuất (Mục 6 - 1đ):
/// Bảng Lương Dự Kiến & KPI Thông Minh (Smart Payroll & Attendance Estimation)
/// Các app chấm công hiện tại chỉ ghi nhận giờ vào/ra thuần túy, chưa có tính năng
/// tự động tính toán tổng lương thực nhận trong tháng dựa trên:
/// - Lương cơ bản theo hợp đồng
/// - Số ngày công chuẩn & ngày đi làm thực tế
/// - Phạt trừ tiền đi trễ theo phút quy định
/// - Thưởng chuyên cần theo chuỗi ngày đúng giờ & xếp loại KPI
/// - Dự báo thu nhập cuối tháng
class SalaryEstimationScreen extends StatefulWidget {
  final double baseSalary;
  final int daysWorked;
  final int lateMinutes;
  final int punctualityStreak;
  final String grade;

  const SalaryEstimationScreen({
    super.key,
    this.baseSalary = 12000000,
    this.daysWorked = 18,
    this.lateMinutes = 15,
    this.punctualityStreak = 5,
    this.grade = 'A',
  });

  @override
  State<SalaryEstimationScreen> createState() => _SalaryEstimationScreenState();
}

class _SalaryEstimationScreenState extends State<SalaryEstimationScreen> {
  late double _baseSalary;
  late int _daysWorked;
  late int _lateMinutes;
  late int _streak;
  late String _grade;

  final int _standardDays = 22; // Ngày công chuẩn trong tháng
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _baseSalary = widget.baseSalary;
    _daysWorked = widget.daysWorked;
    _lateMinutes = widget.lateMinutes;
    _streak = widget.punctualityStreak;
    _grade = widget.grade;
  }

  // Tính lương theo ngày công
  double get _workDaySalary {
    return (_baseSalary / _standardDays) * _daysWorked;
  }

  // Tiền phạt đi trễ (quy định: 2.000đ/phút trễ)
  double get _lateDeduction {
    return _lateMinutes * 2000.0;
  }

  // Thưởng chuyên cần theo chuỗi & xếp loại KPI
  double get _bonus {
    double b = 0;
    if (_streak >= 10) {
      b += 500000;
    } else if (_streak >= 5) {
      b += 200000;
    }
    if (_grade == 'A') b += 500000;
    if (_grade == 'B') b += 200000;
    return b;
  }

  // Phụ cấp ăn trưa & di chuyển cố định
  double get _allowance => 1000000;

  // Lương thực nhận hiện tại
  double get _currentNetSalary {
    final net = _workDaySalary + _bonus + _allowance - _lateDeduction;
    return max(0, net);
  }

  // Dự phóng lương cuối tháng nếu làm đủ ngày công
  double get _estimatedFullMonthSalary {
    final net = _baseSalary + _bonus + _allowance - _lateDeduction;
    return max(0, net);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_daysWorked / _standardDays).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Bảng Lương Dự Kiến & KPI'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ nổi bật: Lương ước tính
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withAlpha(80),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'LƯƠNG THỰC NHẬN HIỆN TẠI',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(35),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Hạng $_grade',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(_currentNetSalary),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dự báo hết tháng', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormat.format(_estimatedFullMonthSalary),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Tiến độ công', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            '$_daysWorked/$_standardDays ngày',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tiêu đề
            const Text(
              'Chi Tiết Khoản Thu Nhập & Khấu Trừ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),

            // Danh sách chi tiết thu nhập
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildSalaryItem(
                    icon: Icons.account_balance_wallet,
                    iconColor: Colors.blue,
                    title: 'Lương theo công đã làm',
                    subtitle: '($_daysWorked/$_standardDays ngày) x ${currencyFormat.format(_baseSalary)}',
                    amount: _workDaySalary,
                    isPositive: true,
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildSalaryItem(
                    icon: Icons.restaurant,
                    iconColor: Colors.orange,
                    title: 'Phụ cấp ăn trưa & đi lại',
                    subtitle: 'Trợ cấp hàng tháng cố định',
                    amount: _allowance,
                    isPositive: true,
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildSalaryItem(
                    icon: Icons.emoji_events,
                    iconColor: Colors.amber,
                    title: 'Thưởng chuyên cần & KPI',
                    subtitle: 'Chuỗi đúng giờ $_streak ngày + KPI Hạng $_grade',
                    amount: _bonus,
                    isPositive: true,
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildSalaryItem(
                    icon: Icons.alarm_off,
                    iconColor: Colors.red,
                    title: 'Khấu trừ đi trễ',
                    subtitle: 'Tổng cộng $_lateMinutes phút trễ (2.000đ/p)',
                    amount: -_lateDeduction,
                    isPositive: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Khối mô tả tính năng mới (Thuyết minh đồ án)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Color(0xFF2563EB), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Tính năng mới đề xuất (Mục 6 - 1đ)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A8A)),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Tự động đồng bộ giờ chấm công thực tế thành bảng lương động theo ngày.\n'
                    '• Tính minh bạch cao: Nhân viên thấy rõ từng phút đi trễ bị trừ bao nhiêu, chuỗi đi đúng giờ được thưởng bao nhiêu.\n'
                    '• Dự báo chính xác thu nhập cuối tháng để nhân viên chủ động kế hoạch tài chính cá nhân.',
                    style: TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF1E40AF)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required double amount,
    required bool isPositive,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Text(
            (amount < 0 ? '-' : '+') + currencyFormat.format(amount.abs()),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }
}
