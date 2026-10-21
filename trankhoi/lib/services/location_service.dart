import 'package:geolocator/geolocator.dart';

class LocationService {
  // Toạ độ mặc định khớp với Văn phòng chính trong CSDL backend (475A Điện Biên Phủ, HUTECH)
  static const double officeLat = 10.8018;
  static const double officeLng = 106.7143;

  Future<Map<String, dynamic>> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {
          'success': true,
          'latitude': officeLat,
          'longitude': officeLng,
          'isMock': true,
          'message': 'Toạ độ: $officeLat, $officeLng (Văn phòng chính - Giả lập)',
        };
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {
            'success': true,
            'latitude': officeLat,
            'longitude': officeLng,
            'isMock': true,
            'message': 'Toạ độ: $officeLat, $officeLng (Văn phòng chính - Giả lập)',
          };
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return {
          'success': true,
          'latitude': officeLat,
          'longitude': officeLng,
          'isMock': true,
          'message': 'Toạ độ: $officeLat, $officeLng (Văn phòng chính - Giả lập)',
        };
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      return {
        'success': true,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'isMock': position.isMocked,
        'message': 'Toạ độ: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)} (GPS Thật)',
      };
    } catch (_) {
      return {
        'success': true,
        'latitude': officeLat,
        'longitude': officeLng,
        'isMock': true,
        'message': 'Toạ độ: $officeLat, $officeLng (Văn phòng chính - Giả lập)',
      };
    }
  }
}
