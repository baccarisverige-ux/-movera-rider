/// A persisted pagehide means the document entered the back-forward cache.
///
/// Installed PWAs also emit this while the app is frozen or backgrounded, so it
/// must not be treated as a real teardown.
bool shouldHandleRidePageHide({required bool persisted}) => !persisted;
