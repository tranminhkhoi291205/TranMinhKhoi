import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:trankhoi/services/api_client.dart';

class AttendanceService {
  final ApiClient _api = ApiClient();

  // Chấm công vào (GPS / QR / FACE)
  Future<Map<String, dynamic>> checkIn({
    required String phuongThuc,
    double? viDo,
    double? kinhDo,
    String? qrToken,
    List<double>? khuonMat,
    String? deviceId,
    bool giaLapViTri = false,
  }) async {
    try {
      final response = await _api.post(
        'ChamCong/check-in',
        body: {
          'phuongThuc': phuongThuc,
          if (viDo != null) 'viDo': viDo,
          if (kinhDo != null) 'kinhDo': kinhDo,
          if (qrToken != null) 'qrToken': qrToken,
          if (khuonMat != null) 'khuonMat': khuonMat,
          if (deviceId != null) 'deviceId': deviceId,
          'giaLapViTri': giaLapViTri,
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Chấm công vào thành công!',
          'data': data,
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Chấm công vào thất bại.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối khi chấm công: $e'};
    }
  }

  // Chấm công ra (GPS / QR / FACE)
  Future<Map<String, dynamic>> checkOut({
    required String phuongThuc,
    double? viDo,
    double? kinhDo,
    String? qrToken,
    List<double>? khuonMat,
    String? deviceId,
    bool giaLapViTri = false,
  }) async {
    try {
      final response = await _api.post(
        'ChamCong/check-out',
        body: {
          'phuongThuc': phuongThuc,
          if (viDo != null) 'viDo': viDo,
          if (kinhDo != null) 'kinhDo': kinhDo,
          if (qrToken != null) 'qrToken': qrToken,
          if (khuonMat != null) 'khuonMat': khuonMat,
          if (deviceId != null) 'deviceId': deviceId,
          'giaLapViTri': giaLapViTri,
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Chấm công ra thành công!',
          'data': data,
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Chấm công ra thất bại.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối khi check-out: $e'};
    }
  }

  // Thông tin chấm công hôm nay của nhân viên
  Future<Map<String, dynamic>?> getTodayStatus() async {
    try {
      final response = await _api.get('ChamCong/hom-nay');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  // Lịch sử chấm công của nhân viên
  Future<List<dynamic>> getMyHistory({DateTime? tuNgay, DateTime? denNgay}) async {
    try {
      Map<String, dynamic> q = {};
      final df = DateFormat('yyyy-MM-dd');
      if (tuNgay != null) q['tuNgay'] = df.format(tuNgay);
      if (denNgay != null) q['denNgay'] = df.format(denNgay);

      final response = await _api.get('ChamCong/cua-toi', queryParams: q);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) return data['items'];
      }
    } catch (_) {}
    return [];
  }

  // Thống kê tháng & Điểm chuyên cần của nhân viên hiện tại
  Future<Map<String, dynamic>?> getMyStats({int? thang, int? nam}) async {
    try {
      Map<String, dynamic> q = {};
      if (thang != null) q['thang'] = thang;
      if (nam != null) q['nam'] = nam;

      final response = await _api.get('ThongKe/cua-toi', queryParams: q);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  // Thống kê tổng quan cho Admin / Quản lý
  Future<Map<String, dynamic>?> getOverviewStats() async {
    try {
      final response = await _api.get('ThongKe/tong-quan');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  // Danh sách vị trí chấm công
  Future<List<dynamic>> getLocations() async {
    try {
      final response = await _api.get('ViTriChamCong');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) return data['items'];
      }
    } catch (_) {}
    return [];
  }

  // Lấy chuỗi mã QR động từ backend (đổi mỗi 60s)
  Future<Map<String, dynamic>?> getDynamicQr(int viTriId) async {
    try {
      final response = await _api.get('ViTriChamCong/$viTriId/qr');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  // Danh sách toàn bộ bản ghi chấm công (Admin/Quản lý)
  Future<Map<String, dynamic>> getAllAttendance({bool? nghiNgo, int page = 1, int pageSize = 20}) async {
    try {
      Map<String, dynamic> q = {'page': page, 'pageSize': pageSize};
      if (nghiNgo != null) q['nghiNgo'] = nghiNgo;

      final response = await _api.get('ChamCong', queryParams: q);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {'total': 0, 'items': []};
  }
}
