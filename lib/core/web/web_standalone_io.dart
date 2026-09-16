/// Native builds are always "installed" — there is no browser tab to tell
/// them apart from. Restore is decided by the caller, not by this flag.
bool webIsInstalledApp() => false;
