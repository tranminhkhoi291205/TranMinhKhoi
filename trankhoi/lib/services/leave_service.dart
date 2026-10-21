import 'dart:convert';
import 'package:trankhoi/services/api_client.dart';

class LeaveService {
  final ApiClient _api = ApiClient();

  // Đơn nghỉ phép của nhân viên hiện tại
  Future<List<dynamic>> getMyLeaves() async {
    try {
      final response = await _api.get('DonNghiPhep/cua-toi');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) return data['items'];
      }
    } catch (_) {}
    return [];
  }

  // Tạo đơn nghỉ phép mới
  Future<Map<String, dynamic>> createLeave({
    required String tuNgay,
    required String denNgay,
    required String lyDo,
  }) async {
    try {
      final response = await _api.post(
        'DonNghiPhep',
        body: {
          'tuNgay': tuNgay,
          'denNgay': denNgay,
          'lyDo': lyDo.trim(),
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Gửi đơn nghỉ phép thành công!'};
      }
      return {'success': false, 'message': data['message'] ?? 'Gửi đơn thất bại.'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Hủy đơn nghỉ phép (khi đang Chờ duyệt)
  Future<Map<String, dynamic>> cancelLeave(int id) async {
    try {
      final response = await _api.delete('DonNghiPhep/$id');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Đã hủy đơn nghỉ phép.'};
      }
      return {'success': false, 'message': data['message'] ?? 'Không thể hủy đơn này.'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Toàn bộ danh sách đơn nghỉ phép (Admin / Quản lý)
  Future<List<dynamic>> getAllLeaves({String? trangThai}) async {
    try {
      Map<String, dynamic> q = {};
      if (trangThai != null && trangThai.isNotEmpty) q['trangThai'] = trangThai;

      final response = await _api.get('DonNghiPhep', queryParams: q);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) return data['items'];
      }
    } catch (_) {}
    return [];
  }

  // Duyệt hoặc từ chối đơn nghỉ phép (Admin / Quản lý)
  Future<Map<String, dynamic>> reviewLeave(int id, {required bool approve, String? note}) async {
    try {
      final response = await _api.put(
        'DonNghiPhep/$id/duyet',
        body: {
          'dongY': approve,
          'ghiChu': note?.trim(),
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': approve ? 'Đã duyệt đơn nghỉ phép!' : 'Đã từ chối đơn nghỉ phép!',
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Thao tác duyệt đơn thất bại.'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
}
