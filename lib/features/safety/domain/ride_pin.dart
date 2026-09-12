import 'dart:math';

class RidePin {
  const RidePin({
    required this.pinId,
    required this.userId,
    required this.pin,
    this.requiredForStart = false,
    this.rotatedAt,
    this.version = 1,
    this.serverAuthoritative = true,
  });

  final String pinId;
  final String userId;
  /// Rider-facing 4-digit PIN. Mock/local only — production backend is authoritative.
  final String pin;
  final bool requiredForStart;
  final DateTime? rotatedAt;
  final int version;
  final bool serverAuthoritative;

  RidePin copyWith({
    String? pinId,
    String? userId,
    String? pin,
    bool? requiredForStart,
    DateTime? rotatedAt,
    int? version,
    bool? serverAuthoritative,
  }) {
    return RidePin(
      pinId: pinId ?? this.pinId,
      userId: userId ?? this.userId,
      pin: pin ?? this.pin,
      requiredForStart: requiredForStart ?? this.requiredForStart,
      rotatedAt: rotatedAt ?? this.rotatedAt,
      version: version ?? this.version,
      serverAuthoritative: serverAuthoritative ?? this.serverAuthoritative,
    );
  }

  Map<String, dynamic> toJson() => {
        'pinId': pinId,
        'userId': userId,
        'pin': pin,
        'required': requiredForStart,
        'rotatedAt': rotatedAt?.toIso8601String(),
        'version': version,
        'serverAuthoritative': serverAuthoritative,
      };

  factory RidePin.fromJson(Map<String, dynamic>? json) {
    if (json == null) return generate();
    final raw = '${json['pin'] ?? ''}';
    final pin = RegExp(r'^\d{4}$').hasMatch(raw) ? raw : generate().pin;
    return RidePin(
      pinId: json['pinId'] as String? ?? 'pin_local',
      userId: json['userId'] as String? ?? 'rider-local',
      pin: pin,
      requiredForStart: json['required'] == true || json['requiredForStart'] == true,
      rotatedAt: DateTime.tryParse('${json['rotatedAt'] ?? ''}'),
      version: json['version'] is int ? json['version'] as int : 1,
      serverAuthoritative: json['serverAuthoritative'] != false,
    );
  }

  static RidePin generate({
    String userId = 'rider-local',
    bool requiredForStart = false,
    int? seed,
  }) {
    final random = seed == null ? Random.secure() : Random(seed);
    final pin = random.nextInt(10000).toString().padLeft(4, '0');
    final now = DateTime.now().toUtc();
    return RidePin(
      pinId: 'pin_${now.microsecondsSinceEpoch}',
      userId: userId,
      pin: pin,
      requiredForStart: requiredForStart,
      rotatedAt: now,
    );
  }
}

class PinVerifyResult {
  const PinVerifyResult({
    required this.valid,
    required this.rideId,
    this.code = 'OK',
  });

  final bool valid;
  final String rideId;
  final String code;

  factory PinVerifyResult.fromJson(Map<String, dynamic> json) {
    return PinVerifyResult(
      valid: json['valid'] == true,
      rideId: json['rideId'] as String? ?? '',
      code: json['code'] as String? ?? 'OK',
    );
  }
}
