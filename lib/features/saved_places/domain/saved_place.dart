class PlaceShortcut {
  const PlaceShortcut({
    required this.title,
    required this.subtitle,
    required this.kind,
    this.id,
  });

  final String title;
  final String subtitle;

  /// What the place is (home, office, gym, ...). Picks the icon; for Home
  /// and Work it is also the slot the address is saved in.
  final String kind;

  /// The identity of a custom place (FLOW-5). Null for Home and Work, which
  /// have one slot each, and for a custom place that is not saved yet.
  final String? id;
}

class SavedPlaceOption {
  const SavedPlaceOption({required this.title, required this.kind});
  final String title;
  final String kind;
}
