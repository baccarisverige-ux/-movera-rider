enum WalletEntryKind { credit, ride, refund, voucher }

class WalletEntry {
  const WalletEntry({
    required this.id,
    required this.kind,
    required this.amountMinor,
    required this.at,
    this.note,
  });

  final String id;
  final WalletEntryKind kind;
  final int amountMinor;
  final DateTime at;
  final String? note;
}

class WalletLedger {
  final List<WalletEntry> _entries = [];

  List<WalletEntry> get entries => List.unmodifiable(_entries);

  int get balanceMinor => _entries.fold(0, (sum, e) => sum + e.amountMinor);

  void add(WalletEntry entry) => _entries.add(entry);
}
