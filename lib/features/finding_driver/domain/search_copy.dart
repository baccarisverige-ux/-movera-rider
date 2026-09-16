/// Rotating search copy. Changes with elapsed time, not every few seconds.
class SearchCopy {
  const SearchCopy({required this.headline, required this.subtitle});

  final String headline;
  final String subtitle;

  static const delayedAfter = Duration(seconds: 60);
  static const rotateEvery = Duration(seconds: 12);

  static const initial = [
    SearchCopy(
      headline: 'Finding your driver',
      subtitle: "We're checking nearby drivers.",
    ),
    SearchCopy(
      headline: 'Checking for nearby drivers',
      subtitle: "We'll update you as soon as a driver accepts.",
    ),
  ];

  static const waiting = [
    SearchCopy(
      headline: 'Still looking for the best match',
      subtitle: "We're still searching — you don't need to do anything.",
    ),
    SearchCopy(
      headline: "We're checking more drivers nearby",
      subtitle: 'Your request is still active.',
    ),
    SearchCopy(
      headline: "Hang tight — we're working on your ride",
      subtitle: "We're checking more nearby drivers.",
    ),
  ];

  static const delayed = [
    SearchCopy(
      headline: "It's busier than usual",
      subtitle: "We'll update you as soon as a driver accepts.",
    ),
    SearchCopy(
      headline: 'Matching is taking a little longer',
      subtitle: "We're still searching — you don't need to do anything.",
    ),
    SearchCopy(
      headline: 'More riders are requesting trips right now',
      subtitle: "We're expanding the search for you.",
    ),
    SearchCopy(
      headline: "We're expanding the search for you",
      subtitle: 'Your request is still active.',
    ),
  ];

  static bool isDelayed(int elapsedSeconds) =>
      elapsedSeconds >= delayedAfter.inSeconds;

  /// Copy is keyed off **phase-local** elapsed, not a global modulo.
  /// 0–19 uses the initial copy, 20–59 uses waiting copy, and 60+ uses
  /// delayed copy starting at delayed[0].
  static SearchCopy forElapsed(int elapsedSeconds) {
    if (elapsedSeconds >= delayedAfter.inSeconds) {
      final step =
          (elapsedSeconds - delayedAfter.inSeconds) ~/ rotateEvery.inSeconds;
      return delayed[step % delayed.length];
    }
    if (elapsedSeconds >= 20) {
      final step = (elapsedSeconds - 20) ~/ rotateEvery.inSeconds;
      return waiting[step % waiting.length];
    }
    final elapsed = elapsedSeconds <= 0 ? 0 : elapsedSeconds;
    final step = elapsed ~/ rotateEvery.inSeconds;
    return initial[step % initial.length];
  }
}
