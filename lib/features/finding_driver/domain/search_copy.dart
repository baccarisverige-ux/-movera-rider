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

  static SearchCopy forElapsed(int elapsedSeconds) {
    final bucket = isDelayed(elapsedSeconds)
        ? delayed
        : elapsedSeconds < 20
            ? initial
            : waiting;
    final step = elapsedSeconds <= 0
        ? 0
        : elapsedSeconds ~/ rotateEvery.inSeconds;
    return bucket[step % bucket.length];
  }
}
