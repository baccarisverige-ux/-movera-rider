
class EtaService {
  Duration estimate({required double meters, required double speedMps}) {
    final speed = speedMps <= 0 ? 8.3 : speedMps;
    return Duration(seconds: (meters / speed).round());
  }
}
