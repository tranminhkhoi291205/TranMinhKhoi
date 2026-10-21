import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:trankhoi/services/attendance_service.dart';

class AdminQrScreen extends StatefulWidget {
  const AdminQrScreen({super.key});

  @override
  State<AdminQrScreen> createState() => _AdminQrScreenState();
}

class _AdminQrScreenState extends State<AdminQrScreen> {
  final AttendanceService _service = AttendanceService();
  String _qrData = "COMPANY_ATTENDANCE_INIT";
  String _locationName = "Văn phòng chính";
  int _secondsLeft = 60;
  Timer? _timer;
  bool _isLoading = true;
  List<dynamic> _locations = [];
  int? _selectedLocationId;

  @override
  void initState() {
    super.initState();
    _initQr();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initQr() async {
    final locs = await _service.getLocations();
    if (mounted) {
      setState(() {
        _locations = locs;
        if (locs.isNotEmpty) {
          _selectedLocationId = locs[0]['id'];
          _locationName = locs[0]['ten'] ?? 'Văn phòng';
        }
      });
      _fetchDynamicQr();
    }
  }

  Future<void> _fetchDynamicQr() async {
    if (_selectedLocationId == null) {
      setState(() {
        _qrData = "QR_OFFLINE_LOCATION_${DateTime.now().millisecondsSinceEpoch}";
        _isLoading = false;
        _secondsLeft = 60;
      });
      _startTimer();
      return;
    }

    final data = await _service.getDynamicQr(_selectedLocationId!);
    if (mounted) {
      setState(() {
        if (data != null && data['qrToken'] != null) {
          _qrData = data['qrToken'];
          _secondsLeft = data['doiSauGiay'] ?? 60;
        } else {
          _qrData = "QR_TOKEN_${_selectedLocationId}_${DateTime.now().millisecondsSinceEpoch}";
          _secondsLeft = 60;
        }
        _isLoading = false;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        _fetchDynamicQr();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Mã QR Điểm Danh Động (Admin)'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.security, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'QR Động Chống Gian Lận (Tự đổi mỗi 60s)',
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_locations.isNotEmpty)
                DropdownButton<int>(
                  value: _selectedLocationId,
                  items: _locations.map<DropdownMenuItem<int>>((loc) {
                    return DropdownMenuItem<int>(
                      value: loc['id'] as int,
                      child: Text('Địa điểm: ${loc['ten']}'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedLocationId = val;
                        final found = _locations.firstWhere((e) => e['id'] == val, orElse: () => null);
                        if (found != null) _locationName = found['ten'];
                      });
                      _fetchDynamicQr();
                    }
                  },
                ),
              Text(
                _locationName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              const Text(
                'Nhân viên dùng Camera trong App quét mã này để check-in',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withAlpha(40),
                      blurRadius: 20,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: _isLoading
                    ? const SizedBox(width: 240, height: 240, child: Center(child: CircularProgressIndicator()))
                    : QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: 240.0,
                        gapless: false,
                      ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, color: Colors.orange, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    'Mã tự làm mới sau: $_secondsLeft giây',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchDynamicQr,
                icon: const Icon(Icons.refresh),
                label: const Text('Làm mới mã ngay lập tức'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
