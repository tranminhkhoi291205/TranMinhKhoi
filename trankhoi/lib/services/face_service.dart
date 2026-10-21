import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class FaceService {
  static const int vectorDimension = 128;

  // Tạo vector khuôn mặt mô phỏng sinh trắc học dựa trên đặc trưng người dùng
  static List<double> generateFaceVector({String? seed, double noiseLevel = 0.05}) {
    final Random random = seed != null ? Random(seed.hashCode) : Random();
    List<double> vector = List.generate(vectorDimension, (_) => (random.nextDouble() * 2.0) - 1.0);

    // Thêm nhiễu nhẹ mô phỏng ánh sáng/góc nghiêng thực tế
    if (noiseLevel > 0) {
      final noiseRandom = Random();
      for (int i = 0; i < vector.length; i++) {
        vector[i] += (noiseRandom.nextDouble() - 0.5) * noiseLevel;
      }
    }

    // Chuẩn hóa vector độ dài đơn vị (Unit Vector) cho so khớp Cosine
    double norm = sqrt(vector.fold(0.0, (sum, val) => sum + (val * val)));
    if (norm > 0) {
      vector = vector.map((v) => v / norm).toList();
    }
    return vector;
  }

  // Lưu vector khuôn mặt cục bộ để so khớp
  static Future<void> saveLocalVector(List<double> vector) async {
    final prefs = await SharedPreferences.getInstance();
    final str = vector.map((e) => e.toString()).join(',');
    await prefs.setString('registered_face_vector', str);
  }

  // Lấy vector khuôn mặt đã lưu
  static Future<List<double>?> getLocalVector() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('registered_face_vector');
    if (str == null || str.isEmpty) return null;
    try {
      return str.split(',').map((e) => double.parse(e)).toList();
    } catch (_) {
      return null;
    }
  }

  // Tính độ tương đồng Cosine (Cosine Similarity)
  static double cosineSimilarity(List<double> v1, List<double> v2) {
    if (v1.length != v2.length || v1.isEmpty) return 0.0;
    double dot = 0.0;
    double n1 = 0.0;
    double n2 = 0.0;
    for (int i = 0; i < v1.length; i++) {
      dot += v1[i] * v2[i];
      n1 += v1[i] * v1[i];
      n2 += v2[i] * v2[i];
    }
    double denom = sqrt(n1) * sqrt(n2);
    if (denom == 0) return 0.0;
    return dot / denom;
  }
}
