/// "Use wallet balance first": how a fare is split between the Movera
/// Wallet and the chosen payment method, in integer öre (DECISIONS.md P1).
///
/// The rider sees whole kronor. The total and the wallet part are each
/// rounded once and the remainder shown is their difference, so the parts
/// on screen always add up to the total on screen.
class WalletSplit {
  const WalletSplit._({required this.totalMinor, required this.walletMinor});

  /// No wallet part: the method pays [totalMinor].
  const WalletSplit.none(this.totalMinor) : walletMinor = 0;

  /// The wallet covers up to [balanceMinor] of [totalMinor].
  factory WalletSplit.of({required int totalMinor, required int balanceMinor}) {
    if (totalMinor <= 0 || balanceMinor <= 0) {
      return WalletSplit.none(totalMinor < 0 ? 0 : totalMinor);
    }
    return WalletSplit._(
      totalMinor: totalMinor,
      walletMinor: balanceMinor >= totalMinor ? totalMinor : balanceMinor,
    );
  }

  /// A split already decided (a booked ride carries its wallet part).
  factory WalletSplit.booked({
    required int totalMinor,
    required int walletMinor,
  }) => WalletSplit.of(totalMinor: totalMinor, balanceMinor: walletMinor);

  final int totalMinor;
  final int walletMinor;

  int get remainderMinor => totalMinor - walletMinor;

  bool get usesWallet => walletMinor > 0;

  /// The wallet pays the whole fare.
  bool get paidByWallet => usesWallet && remainderMinor <= 0;

  int get totalKr => roundMinorToKr(totalMinor);

  int get walletKr => roundMinorToKr(walletMinor);

  /// What the chosen method pays, as shown: total shown minus wallet shown.
  int get remainderKr => totalKr - walletKr;
}

/// The one rounding rule for showing öre as whole kronor.
int roundMinorToKr(int minor) => (minor / 100).round();

/// Kronor (a quote's `totalMinor / 100`, a stored balance) to öre.
int krToMinor(double kr) => (kr * 100).round();

/// The payment line on the Finding and Waiting cards, showing the same
/// split the rider saw before booking: "Visa •••• 4242 · 259 kr", or with
/// the wallet "Visa •••• 4242 209 kr · Wallet 50 kr".
String bookedPaymentLine({
  required String paymentMethod,
  required double priceKr,
  int walletMinor = 0,
  String separator = ' · ',
}) {
  final split = WalletSplit.booked(
    totalMinor: krToMinor(priceKr),
    walletMinor: walletMinor,
  );
  if (!split.usesWallet) {
    return '$paymentMethod$separator${priceKr.round()} kr';
  }
  if (split.paidByWallet) {
    return 'Paid by wallet$separator${split.totalKr} kr';
  }
  return '$paymentMethod ${split.remainderKr} kr$separator'
      'Wallet ${split.walletKr} kr';
}
