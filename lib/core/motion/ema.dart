
class Ema {
  Ema({this.alpha = 0.32});
  final double alpha;
  double? _value;

  double next(double sample) {
    _value = _value == null ? sample : (_value! + alpha * (sample - _value!));
    return _value!;
  }
}
