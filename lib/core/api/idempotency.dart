import 'package:movera_rider/core/utils/request_id.dart';

String newIdempotencyKey(String operation) => '$operation-${newRequestId()}';
