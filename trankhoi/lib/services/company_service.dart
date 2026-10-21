import 'dart:convert';
import 'package:trankhoi/services/api_client.dart';

class CompanyService {
  final ApiClient _api = ApiClient();

  // ================= 1. PHÒNG BAN =================
  Future<List<dynamic>> getDepartments() async {
    try {
      final res = await _api.get('PhongBan');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) return data['items'];
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> createDepartment(String ten, String? moTa) async {
    try {
      final res = await _api.post('PhongBan', body: {'ten': ten.trim(), 'moTa': moTa?.trim()});
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true, 'message': 'Thêm phòng ban thành công!'};
      }
      return {'success': false, 'message': data['message'] ?? 'Thêm thất bại.'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  Future<Map<String, dynamic>> updateDepartment(int id, String ten, String? moTa) async {
    try {
      final res = await _api.put('PhongBan/$id', body: {'ten': ten.trim(), 'moTa': moTa?.trim()});
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'message': 'Cập nhật phòng ban thành công!'};
      }
      return {'success': false, 'message': data['message'] ?? 'Cập nhật thất bại.'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteDepartment(int id) async {
    try {
      final res = await _api.delete('PhongBan/$id');
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'message': 'Đã xóa phòng ban!'};
      }
      return {'success': false, 'message': data['message'] ?? 'Không thể xóa phòng ban.'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // ================= 2. CA LÀM VIỆC =================
  Future<List<dynamic>> getShifts() async {
    try {
      final res = await _api.get('CaLamViec');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) return data['items'];
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> createShift({
    required String ten,
    required String gioBatDau,
    required String gioKetThuc,
    int phutChoPhepTre = 10,
  }) async {
    try {
      final res = await _api.post('CaLamViec', body: {
        'ten': ten.trim(),
        'gioBatDau': gioBatDau,
        'gioKetThuc': gioKetThuc,
        'phutChoPhepTre': phutChoPhepTre,
      });
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true, 'message': 'Tạo ca làm việc thành công!'};
      }
      return {'success': false, 'message': data['message'] ?? 'Tạo ca làm việc thất bại.'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  Future<Map<String, dynamic>> updateShift(
    int id, {
    required String ten,
    required String gioBatDau,
    required String gioKetThuc,
    int phutChoPhepTre = 10,
  }) async {
    try {
      final res = await _api.put('CaLamViec/$id', body: {
        'ten': ten.trim(),
        'gioBatDau': gioBatDau,
        'gioKetThuc': gioKetThuc,
        'phutChoPhepTre': phutChoPhepTre,
      });
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'message': 'Cập nhật ca làm việc thành công!'};
      }
      return {'success': false, 'message': data['message'] ?? 'Cập nhật thất bại.'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteShift(int id) async {
    try {
      final res = await _api.delete('CaLamViec/$id');
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'message': 'Đã xóa ca làm việc!'};
      }
      return {'success': false, 'message': data['message'] ?? 'Không thể xóa ca làm việc.'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // ================= 3. VỊ TRÍ CHẤM CÔNG =================
  Future<List<dynamic>> getLocations() async {
    try {
      final res = await _api.get('ViTriChamCong');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) return data['items'];
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> createLocation({
    required String ten,
    String? diaChi,
    required double latitude,
    required double longitude,
    required int banKinhMet,
  }) async {
    try {
      final res = await _api.post('ViTriChamCong', body: {
        'ten': ten.trim(),
        'diaChi': diaChi?.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'banKinhMet': banKinhMet,
        'hoatDong': true,
      });
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true, 'message': 'Thêm vị trí chấm công thành công!'};
      }
      return {'success': false, 'message': data['message'] ?? 'Thêm thất bại.'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  Future<Map<String, dynamic>> updateLocation(
    int id, {
    required String ten,
    String? diaChi,
    required double latitude,
    required double longitude,
    required int banKinhMet,
    bool hoatDong = true,
  }) async {
    try {
      final res = await _api.put('ViTriChamCong/$id', body: {
        'ten': ten.trim(),
        'diaChi': diaChi?.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'banKinhMet': banKinhMet,
        'hoatDong': hoatDong,
      });
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'message': 'Cập nhật vị trí thành công!'};
      }
      return {'success': false, 'message': data['message'] ?? 'Cập nhật thất bại.'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteLocation(int id) async {
    try {
      final res = await _api.delete('ViTriChamCong/$id');
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'message': 'Đã xóa vị trí chấm công!'};
      }
      return {'success': false, 'message': data['message'] ?? 'Không thể xóa vị trí.'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // ================= 4. TÀI KHOẢN & PHÂN QUYỀN =================
  Future<List<dynamic>> getAccounts({String? search}) async {
    try {
      Map<String, dynamic> q = {};
      if (search != null && search.isNotEmpty) q['search'] = search;
      final res = await _api.get('TaiKhoan', queryParams: q);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) return data;
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> updateRole(String userId, String newRole) async {
    try {
      final res = await _api.put('TaiKhoan/$userId/role', body: {'role': newRole});
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Cập nhật vai trò thành công!'};
      }
      return {'success': false, 'message': data['message'] ?? 'Cập nhật vai trò thất bại.'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }
}
