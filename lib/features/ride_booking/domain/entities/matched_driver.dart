/// Driver payload from matching. UI must not invent missing fields.
class MatchedDriver {
  const MatchedDriver({
    required this.id,
    required this.firstName,
    this.rating,
    this.tripCount,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleColor,
    this.plate,
    this.photoAsset,
    this.vehicleImageAsset,
    this.languages = const [],
    this.yearsOnMovera,
  });

  final String id;
  final String firstName;
  final double? rating;
  final int? tripCount;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? plate;
  final String? photoAsset;
  final String? vehicleImageAsset;
  final List<String> languages;
  final int? yearsOnMovera;

  String get vehicleLabel {
    final parts = [
      if (vehicleColor != null && vehicleColor!.isNotEmpty) vehicleColor,
      if (vehicleMake != null && vehicleMake!.isNotEmpty) vehicleMake,
      if (vehicleModel != null && vehicleModel!.isNotEmpty) vehicleModel,
    ];
    return parts.join(' ');
  }

  String? get ratingLabel {
    final value = rating;
    if (value == null) return null;
    return value.toStringAsFixed(value == value.roundToDouble() ? 1 : 2);
  }

  String? get tripsLabel {
    final count = tripCount;
    if (count == null) return null;
    return '$count trips';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    if (rating != null) 'rating': rating,
    if (tripCount != null) 'tripCount': tripCount,
    if (vehicleMake != null) 'vehicleMake': vehicleMake,
    if (vehicleModel != null) 'vehicleModel': vehicleModel,
    if (vehicleColor != null) 'vehicleColor': vehicleColor,
    if (plate != null) 'plate': plate,
    if (photoAsset != null) 'photoAsset': photoAsset,
    if (vehicleImageAsset != null) 'vehicleImageAsset': vehicleImageAsset,
    if (languages.isNotEmpty) 'languages': languages,
    if (yearsOnMovera != null) 'yearsOnMovera': yearsOnMovera,
  };

  static MatchedDriver? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['id'] as String? ?? '';
    final firstName =
        json['firstName'] as String? ?? json['name'] as String? ?? '';
    if (id.isEmpty || firstName.isEmpty) return null;
    final langs = json['languages'];
    return MatchedDriver(
      id: id,
      firstName: firstName,
      rating: (json['rating'] as num?)?.toDouble(),
      tripCount: (json['tripCount'] as num?)?.toInt(),
      vehicleMake: json['vehicleMake'] as String?,
      vehicleModel: json['vehicleModel'] as String?,
      vehicleColor: json['vehicleColor'] as String?,
      plate: json['plate'] as String?,
      photoAsset: json['photoAsset'] as String?,
      vehicleImageAsset: json['vehicleImageAsset'] as String?,
      languages: langs is List
          ? langs.whereType<String>().where((item) => item.isNotEmpty).toList()
          : const [],
      yearsOnMovera: (json['yearsOnMovera'] as num?)?.toInt(),
    );
  }
}
