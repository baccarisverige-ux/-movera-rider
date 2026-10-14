/// Marks a repository implementation whose source of truth is the Movera
/// backend, not this device (ARCH-7).
///
/// A staging or production composition may only expose a rider-facing
/// repository that implements this marker; anything else (SharedPreferences,
/// an in-memory list) is device-only and is rejected by
/// `RepositoryComposition.validate` unless the feature it serves is switched
/// off for that flavor. The marker is opt-in on purpose: a new local
/// implementation fails release composition until someone decides otherwise.
abstract interface class ServerBackedRepository {}

/// Marks the stand-in a release build composes for a feature that is
/// switched off there: it holds no data and refuses every write, so nothing
/// can look saved that no server knows about (ARCH-6, ARCH-7).
abstract interface class FeatureOffRepository {}
