/// In-process Safety mock. Same paths/DTOs the real API will use.
class SafetyMockApi {
  final Map<String, dynamic> preferences = {
    'userId': 'rider-local',
    'pinRequired': false,
    'tripShareEnabled': false,
    'tripShareMode': 'manual',
    'tripShareContactIds': <String>[],
    'rideCheckEnabled': false,
    'version': 1,
  };

  Map<String, dynamic> pin = _newPin(required: false);
  final List<Map<String, dynamic>> contacts = [];
  final Map<String, Map<String, dynamic>> shares = {};
  Map<String, dynamic> rideCheck = {
    'enabled': false,
    'userId': 'rider-local',
  };
  final List<Map<String, dynamic>> events = [];
  final List<Map<String, dynamic>> recordings = [];
  String? lastLoggedPin;

  static Map<String, dynamic> _newPin({required bool required}) {
    final now = DateTime.now().toUtc();
    final n = now.microsecondsSinceEpoch % 10000;
    return {
      'pinId': 'pin_${now.microsecondsSinceEpoch}',
      'userId': 'rider-local',
      'pin': n.toString().padLeft(4, '0'),
      'required': required,
      'rotatedAt': now.toIso8601String(),
      'version': 1,
      'serverAuthoritative': true,
    };
  }

  /// Returns null if the path is not a Safety route.
  ({int status, Map<String, dynamic> payload})? handle({
    required String method,
    required String path,
    required Map<String, dynamic> body,
    required String requestId,
  }) {
    if (path == '/api/v1/safety/preferences' && method == 'GET') {
      return (status: 200, payload: {'code': 'OK', 'preferences': preferences});
    }
    if (path == '/api/v1/safety/preferences' && method == 'PATCH') {
      preferences.addAll({
        if (body.containsKey('pinRequired')) 'pinRequired': body['pinRequired'] == true,
        if (body.containsKey('tripShareEnabled'))
          'tripShareEnabled': body['tripShareEnabled'] == true,
        if (body.containsKey('tripShareMode'))
          'tripShareMode': '${body['tripShareMode']}',
        if (body['tripShareContactIds'] is List)
          'tripShareContactIds': List<String>.from(
            (body['tripShareContactIds'] as List).map((e) => '$e'),
          ),
        if (body.containsKey('rideCheckEnabled'))
          'rideCheckEnabled': body['rideCheckEnabled'] == true,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
      pin['required'] = preferences['pinRequired'] == true;
      rideCheck['enabled'] = preferences['rideCheckEnabled'] == true;
      return (status: 200, payload: {'code': 'OK', 'preferences': preferences});
    }
    if (path == '/api/v1/safety/pin' && method == 'GET') {
      return (status: 200, payload: {'code': 'OK', 'pin': pin});
    }
    if (path == '/api/v1/safety/pin/rotate' && method == 'POST') {
      pin = _newPin(required: preferences['pinRequired'] == true);
      lastLoggedPin = null;
      return (status: 200, payload: {'code': 'OK', 'pin': pin});
    }
    final verify = RegExp(r'^/api/v1/rides/([^/]+)/pin/verify$').firstMatch(path);
    if (verify != null && method == 'POST') {
      final rideId = verify.group(1)!;
      final offered = '${body['pin'] ?? ''}';
      final required = pin['required'] == true;
      final valid = offered == pin['pin'];
      if (required && !valid) {
        return (
          status: 409,
          payload: {
            'code': 'PIN_INVALID',
            'valid': false,
            'rideId': rideId,
            'serverAuthoritative': true,
          },
        );
      }
      return (
        status: 200,
        payload: {'code': 'OK', 'valid': valid, 'rideId': rideId},
      );
    }
    if (path == '/api/v1/safety/contacts' && method == 'GET') {
      return (status: 200, payload: {'code': 'OK', 'contacts': contacts});
    }
    if (path == '/api/v1/safety/contacts' && method == 'POST') {
      if (contacts.length >= 5) {
        return (
          status: 409,
          payload: {'code': 'CONTACT_LIMIT', 'message': 'Max 5 contacts'},
        );
      }
      final created = Map<String, dynamic>.from(body);
      created['id'] = created['id'] ?? 'ec_$requestId';
      created['userId'] = created['userId'] ?? 'rider-local';
      created['createdAt'] =
          created['createdAt'] ?? DateTime.now().toUtc().toIso8601String();
      if (contacts.isEmpty) created['isPrimary'] = true;
      contacts.add(created);
      return (status: 200, payload: {'code': 'OK', 'contact': created});
    }
    final contactId = RegExp(r'^/api/v1/safety/contacts/([^/]+)$').firstMatch(path);
    if (contactId != null && method == 'PATCH') {
      final id = contactId.group(1);
      final index = contacts.indexWhere((c) => c['id'] == id);
      if (index < 0) {
        return (status: 404, payload: {'code': 'NOT_FOUND'});
      }
      contacts[index] = {...contacts[index], ...body, 'id': id};
      return (status: 200, payload: {'code': 'OK', 'contact': contacts[index]});
    }
    if (contactId != null && method == 'DELETE') {
      final id = contactId.group(1);
      contacts.removeWhere((c) => c['id'] == id);
      if (contacts.isNotEmpty && !contacts.any((c) => c['isPrimary'] == true)) {
        contacts[0]['isPrimary'] = true;
      }
      return (status: 200, payload: {'code': 'OK'});
    }
    final primary = RegExp(r'^/api/v1/safety/contacts/([^/]+)/primary$').firstMatch(path);
    if (primary != null && method == 'POST') {
      final id = primary.group(1);
      for (final contact in contacts) {
        contact['isPrimary'] = contact['id'] == id;
      }
      return (status: 200, payload: {'code': 'OK', 'contacts': contacts});
    }
    final share = RegExp(r'^/api/v1/rides/([^/]+)/share$').firstMatch(path);
    if (share != null) {
      final rideId = share.group(1)!;
      if (method == 'POST') {
        final now = DateTime.now().toUtc();
        final token = 'tok_$requestId';
        final row = {
          'shareId': 'share_$rideId',
          'rideId': rideId,
          'userId': 'rider-local',
          'contactIds': body['contactIds'] ?? [],
          'startedAt': now.toIso8601String(),
          'expiresAt': now.add(const Duration(hours: 6)).toIso8601String(),
          'shareToken': token,
          'isActive': true,
          'serverAuthoritative': true,
        };
        shares[rideId] = row;
        return (status: 200, payload: {'code': 'OK', 'share': row});
      }
      if (method == 'GET') {
        final row = shares[rideId];
        if (row == null) {
          return (status: 404, payload: {'code': 'NOT_FOUND'});
        }
        return (status: 200, payload: {'code': 'OK', 'share': row});
      }
      if (method == 'PATCH') {
        final row = {...?shares[rideId], ...body, 'rideId': rideId};
        shares[rideId] = row;
        return (status: 200, payload: {'code': 'OK', 'share': row});
      }
      if (method == 'DELETE') {
        final row = shares[rideId];
        if (row != null) {
          row['isActive'] = false;
        }
        return (status: 200, payload: {'code': 'OK'});
      }
    }
    if (path == '/api/v1/safety/ridecheck/preferences' && method == 'GET') {
      return (status: 200, payload: {'code': 'OK', 'policy': rideCheck});
    }
    if (path == '/api/v1/safety/ridecheck/preferences' && method == 'PATCH') {
      rideCheck = {
        ...rideCheck,
        'enabled': body['enabled'] == true,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };
      preferences['rideCheckEnabled'] = rideCheck['enabled'] == true;
      return (status: 200, payload: {'code': 'OK', 'policy': rideCheck});
    }
    final safetyEvents =
        RegExp(r'^/api/v1/rides/([^/]+)/safety-events$').firstMatch(path);
    if (safetyEvents != null && method == 'POST') {
      final rideId = safetyEvents.group(1)!;
      final event = {
        ...body,
        'eventId': body['eventId'] ?? 'ev_$requestId',
        'rideId': rideId,
        'status': body['status'] ?? 'pending',
        'at': body['at'] ?? DateTime.now().toUtc().toIso8601String(),
        'serverAuthoritative': true,
      };
      if (events.any((e) => e['eventId'] == event['eventId'])) {
        return (
          status: 200,
          payload: {
            'code': 'OK',
            'event': events.firstWhere((e) => e['eventId'] == event['eventId']),
          },
        );
      }
      events.add(event);
      return (status: 200, payload: {'code': 'OK', 'event': event});
    }
    if (safetyEvents != null && method == 'GET') {
      final rideId = safetyEvents.group(1);
      final list = events.where((e) => e['rideId'] == rideId).toList();
      return (status: 200, payload: {'code': 'OK', 'events': list});
    }
    final respond = RegExp(
      r'^/api/v1/rides/([^/]+)/safety-events/([^/]+)/respond$',
    ).firstMatch(path);
    if (respond != null && method == 'POST') {
      final eventId = respond.group(2);
      final index = events.indexWhere((e) => e['eventId'] == eventId);
      if (index < 0) {
        return (status: 404, payload: {'code': 'NOT_FOUND'});
      }
      final action = '${body['action'] ?? 'acknowledged'}';
      events[index]['status'] = action == 'resolved' ? 'resolved' : 'acknowledged';
      return (status: 200, payload: {'code': 'OK', 'event': events[index]});
    }
    final audioInit =
        RegExp(r'^/api/v1/rides/([^/]+)/safety-audio/init$').firstMatch(path);
    if (audioInit != null && method == 'POST') {
      final rec = {
        'id': 'aud_$requestId',
        'rideId': audioInit.group(1),
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'uploadStatus': 'localOnly',
        'encryptionState': 'local',
        'durationMs': 0,
      };
      recordings.add(rec);
      return (status: 200, payload: {'code': 'OK', 'recording': rec});
    }
    final audio =
        RegExp(r'^/api/v1/rides/([^/]+)/safety-audio/([^/]+)(/complete)?$')
            .firstMatch(path);
    if (audio != null) {
      final recordingId = audio.group(2);
      final complete = audio.group(3) != null;
      final index = recordings.indexWhere((r) => r['id'] == recordingId);
      if (method == 'POST' && complete) {
        if (index < 0) {
          return (status: 404, payload: {'code': 'NOT_FOUND'});
        }
        recordings[index]['endedAt'] = DateTime.now().toUtc().toIso8601String();
        recordings[index]['durationMs'] = body['durationMs'] ?? 0;
        recordings[index]['uploadStatus'] = 'localOnly';
        return (
          status: 200,
          payload: {'code': 'OK', 'recording': recordings[index]},
        );
      }
      if (method == 'DELETE') {
        recordings.removeWhere((r) => r['id'] == recordingId);
        return (status: 200, payload: {'code': 'OK'});
      }
    }
    return null;
  }
}

SafetyMockApi? _processSafety;
SafetyMockApi safetyMockForProcess() => _processSafety ??= SafetyMockApi();
void resetSafetyMockForProcess() => _processSafety = null;
