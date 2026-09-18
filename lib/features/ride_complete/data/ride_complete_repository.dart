/// Tip options offered after a ride, in SEK.
///
/// These are a product decision rather than backend data — the amounts a rider
/// may choose, not a record of anything — so they are defined here and shown
/// whether or not a backend is connected. An empty catalog is still honoured:
/// the screen falls back to its unavailable state rather than inventing one.
class TipCatalog {
  const TipCatalog({List<String>? amounts}) : _amounts = amounts;

  static const defaults = <String>['10 kr', '20 kr', '30 kr'];

  final List<String>? _amounts;

  List<String> amounts() => _amounts ?? defaults;
}
