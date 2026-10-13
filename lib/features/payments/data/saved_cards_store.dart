import 'dart:convert';

import 'package:movera_rider/core/storage/preferences_store.dart';
import 'package:movera_rider/features/payments/domain/saved_card.dart';

/// Where the demo saved cards live. Only the reference data in [SavedCard]
/// is written; never a full card number or CVC.
abstract class SavedCardsStore {
  Future<List<SavedCard>> read();
  Future<void> write(List<SavedCard> cards);
}

class PrefsSavedCardsStore implements SavedCardsStore {
  const PrefsSavedCardsStore();

  static const key = 'movera_saved_cards';

  @override
  Future<List<SavedCard>> read() async {
    final prefs = await PreferencesStore.load();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.map(SavedCard.fromJson).whereType<SavedCard>().toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> write(List<SavedCard> cards) async {
    final prefs = await PreferencesStore.load();
    if (cards.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(
      key,
      jsonEncode(cards.map((c) => c.toJson()).toList()),
    );
  }
}

class MemorySavedCardsStore implements SavedCardsStore {
  MemorySavedCardsStore([List<SavedCard>? cards]) : cards = [...?cards];

  List<SavedCard> cards;

  @override
  Future<List<SavedCard>> read() async => List.unmodifiable(cards);

  @override
  Future<void> write(List<SavedCard> cards) async {
    this.cards = [...cards];
  }
}
