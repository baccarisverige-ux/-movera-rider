export 'current_address_lookup_stub.dart'
    if (dart.library.io) 'current_address_lookup_native.dart'
    if (dart.library.html) 'current_address_lookup_web.dart';
