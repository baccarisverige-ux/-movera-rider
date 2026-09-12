enum RideCheckEventType {
  unexpectedStop,
  routeDeviation,
  destinationPassed,
  movementLost,
  possibleCrash,
  manualSafetyCheck,
  resolved,
}

enum RideCheckStatus { idle, pending, acknowledged, resolved, stale }

class RideCheckPolicy {
  const RideCheckPolicy({
    this.enabled = false,
    this.userId = 'rider-local',
    this.updatedAt,
  });

  final bool enabled;
  final String userId;
  final DateTime? updatedAt;

  RideCheckPolicy copyWith({bool? enabled, String? userId, DateTime? updatedAt}) {
    return RideCheckPolicy(
      enabled: enabled ?? this.enabled,
      userId: userId ?? this.userId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'userId': userId,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory RideCheckPolicy.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RideCheckPolicy();
    return RideCheckPolicy(
      enabled: json['enabled'] == true,
      userId: json['userId'] as String? ?? 'rider-local',
      updatedAt: DateTime.tryParse('${json['updatedAt'] ?? ''}'),
    );
  }
}

class RideCheckEvent {
  const RideCheckEvent({
    required this.eventId,
    required this.rideId,
    required this.type,
    required this.at,
    this.status = RideCheckStatus.pending,
    this.userId = 'rider-local',
    this.payload = const {},
  });

  final String eventId;
  final String rideId;
  final RideCheckEventType type;
  final DateTime at;
  final RideCheckStatus status;
  final String userId;
  final Map<String, dynamic> payload;

  RideCheckEvent copyWith({
    String? eventId,
    String? rideId,
    RideCheckEventType? type,
    DateTime? at,
    RideCheckStatus? status,
    String? userId,
    Map<String, dynamic>? payload,
  }) {
    return RideCheckEvent(
      eventId: eventId ?? this.eventId,
      rideId: rideId ?? this.rideId,
      type: type ?? this.type,
      at: at ?? this.at,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'rideId': rideId,
        'type': type.name,
        'at': at.toIso8601String(),
        'status': status.name,
        'userId': userId,
        'payload': payload,
        'serverAuthoritative': true,
      };

  factory RideCheckEvent.fromJson(Map<String, dynamic> json) {
    return RideCheckEvent(
      eventId: json['eventId'] as String? ?? json['id'] as String? ?? '',
      rideId: json['rideId'] as String? ?? '',
      type: RideCheckEventType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => RideCheckEventType.manualSafetyCheck,
      ),
      at: DateTime.tryParse('${json['at']}') ?? DateTime.fromMillisecondsSinceEpoch(0),
      status: RideCheckStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => RideCheckStatus.pending,
      ),
      userId: json['userId'] as String? ?? 'rider-local',
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : const {},
    );
  }
}

class RideCheckAlert {
  const RideCheckAlert({required this.event, this.title, this.body});
  final RideCheckEvent event;
  final String? title;
  final String? body;
}

class RideCheckResponse {
  const RideCheckResponse({
    required this.eventId,
    required this.action,
    required this.at,
  });

  final String eventId;
  final String action;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'action': action,
        'at': at.toIso8601String(),
      };
}
