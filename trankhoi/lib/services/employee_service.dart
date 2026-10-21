import 'dart:convert';
import 'package:trankhoi/services/api_client.dart';

class EmployeeService {
  final ApiClient _api = ApiClient();

  // Lấy danh sách nhân viên
  Future<List<dynamic>> getAll({int? phongBanId, bool? dangLamViec, String? timKiem}) async {
    try {
      Map<String, dynamic> q = {};
      if (phongBanId != null) q['phongBanId'] = phongBanId;
      if (dangLamViec != null) q['dangLamViec'] = dangLamViec;
      if (timKiem != null && timKiem.isNotEmpty) q['search'] = timKiem;

      final response = await _api.get('NhanVien', queryParams: q);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) return data['items'];
      }
    } catch (_) {}
    return [];
  }

  // Lấy chi tiết 1 nhân viên
  Future<Map<String, dynamic>?> getById(int id) async {
    try {
      final response = await _api.get('NhanVien/$id');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  // Thêm mới nhân viên
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('NhanVien', body: data);
      final resData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': resData, 'message': 'Thêm nhân viên thành công!'};
      }
      return {'success': false, 'message': resData['message'] ?? 'Thêm nhân viên thất bại.'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Sửa nhân viên
  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('NhanVien/$id', body: data);
      final resData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': resData, 'message': 'Cập nhật thông tin nhân viên thành công!'};
      }
      return {'success': false, 'message': resData['message'] ?? 'Cập nhật thất bại.'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Xóa nhân viên
  Future<Map<String, dynamic>> delete(int id) async {
    try {
      final response = await _api.delete('NhanVien/$id');
      final resData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': resData['message'] ?? 'Đã xóa nhân viên!'};
      }
      return {'success': false, 'message': resData['message'] ?? 'Không thể xóa nhân viên.'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Đăng ký vector khuôn mặt cho nhân viên hiện tại
  Future<Map<String, dynamic>> registerFace(List<double> vector) async {
    try {
      final response = await _api.post(
        'NhanVien/me/khuon-mat',
        body: {'khuonMat': vector},
      );
      final resData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': resData['message'] ?? 'Đăng ký khuôn mặt thành công!'};
      }
      return {'success': false, 'message': resData['message'] ?? 'Đăng ký khuôn mặt thất bại.'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi đăng ký khuôn mặt: $e'};
    }
  }

  // Danh sách phòng ban
  Future<List<dynamic>> getDepartments() async {
    try {
      final response = await _api.get('PhongBan');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
      }
    } catch (_) {}
    return [];
  }

  // Danh sách ca làm việc
  Future<List<dynamic>> getShifts() async {
    try {
      final response = await _api.get('CaLamViec');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
      }
    } catch (_) {}
    return [];
  }
}
