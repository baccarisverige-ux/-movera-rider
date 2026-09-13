class RideNotes {
  const RideNotes({
    this.bags = false,
    this.pet = false,
    this.baby = false,
    this.child = false,
  });

  final bool bags;
  final bool pet;
  final bool baby;
  final bool child;

  static const empty = RideNotes();

  bool get isEmpty => !bags && !pet && !baby && !child;

  List<String> get selected {
    return [
      if (bags) 'Bags',
      if (pet) 'Pet',
      if (baby) 'Baby',
      if (child) 'Child',
    ];
  }

  RideNotes copyWith({
    bool? bags,
    bool? pet,
    bool? baby,
    bool? child,
  }) {
    return RideNotes(
      bags: bags ?? this.bags,
      pet: pet ?? this.pet,
      baby: baby ?? this.baby,
      child: child ?? this.child,
    );
  }

  RideNotes toggle(String key) {
    switch (key) {
      case 'bags':
        return copyWith(bags: !bags);
      case 'pet':
        return copyWith(pet: !pet);
      case 'baby':
        return copyWith(baby: !baby);
      case 'child':
        return copyWith(child: !child);
      default:
        return this;
    }
  }

  Map<String, dynamic> toJson() => {
        'bags': bags,
        'pet': pet,
        'baby': baby,
        'child': child,
      };

  factory RideNotes.fromJson(Map<String, dynamic>? json) {
    if (json == null) return empty;
    return RideNotes(
      bags: json['bags'] == true,
      pet: json['pet'] == true,
      baby: json['baby'] == true,
      child: json['child'] == true,
    );
  }
}
