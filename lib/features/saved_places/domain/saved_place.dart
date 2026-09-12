class PlaceShortcut {
  const PlaceShortcut({
    required this.title,
    required this.subtitle,
    required this.kind,
  });

  final String title;
  final String subtitle;
  final String kind;
}

class SavedPlaceOption {
  const SavedPlaceOption({required this.title, required this.kind});
  final String title;
  final String kind;
}
