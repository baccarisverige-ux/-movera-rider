class SavedPlace {
  const SavedPlace({
    required this.id,
    required this.label,
    required this.address,
  });

  final String id;
  final String label;
  final String address;

  factory SavedPlace.fromDto(Map<String, dynamic> dto) {
    return SavedPlace(
      id: dto['id'] as String? ?? '',
      label: dto['label'] as String? ?? '',
      address: dto['address'] as String? ?? '',
    );
  }
}
