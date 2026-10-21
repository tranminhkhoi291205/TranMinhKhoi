import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  void startListening(Function(double x, double y, double z) onUpdate) {
    _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      onUpdate(event.x, event.y, event.z);
    });
  }

  void stopListening() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }
}
