import 'package:web/web.dart' as web;

const _key = 'movera_search_live';

/// sessionStorage is the right scope: it survives a reload of this tab but not
/// a fresh visit, so a ride abandoned days ago is forgotten quietly.
web.Storage? get _storage {
  try {
    return web.window.sessionStorage;
  } catch (_) {
    return null;
  }
}

/// Remember that a ride was live, so that if this document is replaced — a
/// reload during Finding Driver, say — the next one can say what happened.
void webMarkSearchLive() {
  try {
    _storage?.setItem(_key, '1');
  } catch (_) {}
}

/// The ride ended on purpose; there is nothing to apologise for next time.
void webClearSearchLive() {
  try {
    _storage?.removeItem(_key);
  } catch (_) {}
}

/// True once if a ride was still live when the previous document ended.
bool webTakeSearchInterrupted() {
  try {
    final storage = _storage;
    if (storage == null || storage.getItem(_key) == null) return false;
    storage.removeItem(_key);
    return true;
  } catch (_) {
    return false;
  }
}
