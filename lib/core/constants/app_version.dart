/// The running build's version for telemetry (CODE-20). CI passes the
/// pubspec version with `--dart-define=MOVERA_APP_VERSION=<version>`; local
/// builds report `dev`, never a version they are not.
const appVersion = String.fromEnvironment(
  'MOVERA_APP_VERSION',
  defaultValue: 'dev',
);
