import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/features/wallet/application/wallet_controller.dart';
import 'package:movera_rider/shared/design_system/movera_empty_state.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';

Future<void> showVoucherUnavailableSheet(BuildContext context) async {
  const ink = Color(0xFF11181D);
  const muted = Color(0xFF5C656C);

  await MoveraSheet.show<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.confirmation_number_outlined,
                color: ink,
                size: 34,
              ),
              const SizedBox(height: 14),
              Text(
                'Vouchers aren’t available yet',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Validated Movera voucher codes will appear here when the service launches.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: muted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class WalletHome extends StatefulWidget {
  const WalletHome({super.key, this.wallet});

  final WalletController? wallet;

  @override
  State<WalletHome> createState() => _WalletHomeState();
}

class _WalletHomeState extends State<WalletHome> {
  static const Color _ink = Color(0xFF11181D);
  static const Color _muted = Color(0xFF5C656C);
  static const Color _line = Color(0xFFE6E8E7);
  late final WalletController _wallet = widget.wallet ?? WalletController();
  bool get _demoPayments = AppScope.instance.environment.allowsMockTransport;

  double _balance = 0;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  TextStyle _style(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = _ink,
    double? height,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  Future<void> _restore() async {
    if (!mounted) return;
    if (!_loading || _failed) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    try {
      final balance = await _wallet.loadBalance();
      if (!mounted) return;
      setState(() {
        _balance = balance;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _saveBalance(double value) async {
    final next = await _wallet.topUp(
      previous: _balance,
      amount: value - _balance,
    );
    if (!mounted || next == null) return;
    setState(() => _balance = next);
  }

  Future<void> _openAddFunds() async {
    if (!_demoPayments) return;
    int amount = 200;
    final funded = await MoveraSheet.show<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _line,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Add funds',
                      style: _style(20, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Demo top-up uses a simulated payment. No card or provider is charged.',
                      style: _style(12, weight: FontWeight.w400, color: _muted),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (final value in [100, 200, 500]) ...[
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setSheetState(() => amount = value),
                              child: Container(
                                height: 46,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: amount == value
                                      ? _ink
                                      : const Color(0xFFF4F5F4),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  'kr $value',
                                  style: _style(
                                    13,
                                    weight: FontWeight.w600,
                                    color: amount == value
                                        ? Colors.white
                                        : _ink,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (value != 500) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        child: const Text('Simulate top-up'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (funded == true) {
      await _saveBalance(_balance + amount);
    }
  }

  Future<void> _openVoucher() async {
    await showVoucherUnavailableSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Back',
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 42,
                          height: 42,
                          child: Icon(Icons.arrow_back_rounded, color: _ink),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text('Wallet', style: _style(16, weight: FontWeight.w700)),
                  const Spacer(),
                  const SizedBox(width: 42),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 196,
                width: double.infinity,
                child: Image.asset(
                  excludeFromSemantics: true,
                  'assets/images/wallet_rider_3d.webp',
                  fit: BoxFit.contain,
                  cacheHeight: 400,
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Add funds to your wallet',
                  textAlign: TextAlign.center,
                  style: _style(15, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Top up for rides.',
                  textAlign: TextAlign.center,
                  style: _style(12, color: _muted),
                ),
              ),
              const SizedBox(height: 16),
              if (_failed)
                MoveraEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Couldn’t load wallet',
                  message: 'Your balance couldn’t be read. Try again.',
                  actionLabel: 'Retry',
                  onAction: _restore,
                  compact: true,
                )
              else if (_loading)
                const MoveraEmptyState(
                  icon: Icons.hourglass_empty_rounded,
                  title: 'Loading wallet',
                  message: 'Checking your balance.',
                  compact: true,
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF11181D), Color(0xFF2D5878)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF11181D).withValues(alpha: 0.28),
                        blurRadius: 28,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'MOVERA',
                            style: _style(
                              11,
                              weight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.7),
                            ).copyWith(letterSpacing: 2.2),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.contactless_rounded,
                            color: Colors.white.withValues(alpha: 0.86),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Available balance',
                        style: _style(
                          12,
                          weight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'kr ${_balance.toStringAsFixed(0)}',
                        style: _style(
                          34,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: _demoPayments ? _openAddFunds : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _ink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _demoPayments ? 'Add funds (demo)' : 'Add funds unavailable',
                            style: _style(14, weight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _openVoucher,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    side: const BorderSide(color: _line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Vouchers unavailable',
                    style: _style(14, weight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _demoPayments
                    ? 'Demo top-ups use simulated payments.'
                    : 'Wallet top-ups are unavailable until payment processing is connected.',
                style: _style(12.5, color: _muted, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const Color _ink = Color(0xFF171C1F);
  static const Color _muted = Color(0xFF5C656C);
  static const Color _surface = Color(0xFFF4F5F4);
  static const Color _line = Color(0xFFE6E8E7);
  static const Color _accent = Color(0xFF356879);
  final _wallet = WalletController();

  bool _businessProfile = false;
  String _selectedMethod = 'apple';
  List<Map<String, String>> _extraMethods = [];

  @override
  void initState() {
    super.initState();
    _restorePaymentSettings();
  }

  TextStyle _style(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = _ink,
    double? height,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  Future<void> _restorePaymentSettings() async {
    final saved = await _wallet.loadPayments();
    if (!mounted) return;
    setState(() {
      _selectedMethod = saved.defaultMethod;
      _businessProfile = saved.business;
      _extraMethods = saved.extraMethods;
    });
  }

  Future<void> _savePaymentSettings() async {
    await _wallet.savePayments(
      WalletPaymentSettings(
        defaultMethod: _selectedMethod,
        business: _businessProfile,
        extraMethods: _extraMethods,
      ),
    );
  }

  void _selectMethod(String id) {
    setState(() => _selectedMethod = id);
    _savePaymentSettings();
  }

  void _selectProfile(bool business) {
    setState(() => _businessProfile = business);
    _savePaymentSettings();
  }

  Future<void> _openAddPaymentMethod() async {
    await MoveraSheet.show<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: _line,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Add payment method', style: _style(17, weight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                    color: _muted,
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 5),
              _unavailableMethodChoice(
                brand: 'cards',
                title: 'Debit or credit card',
                subtitle: 'Unavailable until secure card setup is connected',
              ),
              _unavailableMethodChoice(
                brand: 'paypal',
                title: 'PayPal',
                subtitle: 'Unavailable until PayPal authorization is connected',
              ),
              _unavailableMethodChoice(
                brand: 'klarna',
                title: 'Klarna',
                subtitle: 'Unavailable until Klarna authorization is connected',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _unavailableMethodChoice({
    required String brand,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          _brandMark(brand),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _style(12.5, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: _style(9.5, weight: FontWeight.w400, color: _muted)),
              ],
            ),
          ),
          const Icon(Icons.lock_outline_rounded, color: _muted, size: 19),
        ],
      ),
    );
  }

  Future<void> _openVoucherForm() async {
    await showVoucherUnavailableSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How would you like\nto pay?',
                      style: _style(27, weight: FontWeight.w700, height: 1.18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose the default method for your Movera rides.',
                      style: _style(
                        11.5,
                        weight: FontWeight.w400,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _profileSelector(),
                    const SizedBox(height: 25),
                    _sectionLabel('PAYMENT METHODS'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _line),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.035),
                            blurRadius: 22,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _paymentTile(
                            id: 'wallet',
                            title: 'Movera Wallet',
                            detail: 'Pay from your balance',
                            brand: 'wallet',
                          ),
                          const Divider(
                            height: 1,
                            indent: 62,
                            endIndent: 16,
                            color: _line,
                          ),
                          _paymentTile(
                            id: 'apple',
                            title: 'Apple Pay',
                            detail: 'Available by default',
                            brand: 'apple',
                          ),
                          const Divider(
                            height: 1,
                            indent: 62,
                            endIndent: 16,
                            color: _line,
                          ),
                          _paymentTile(
                            id: 'google',
                            title: 'Google Pay',
                            detail: 'Available by default',
                            brand: 'google',
                          ),
                          const Divider(
                            height: 1,
                            indent: 62,
                            endIndent: 16,
                            color: _line,
                          ),
                          _paymentTile(
                            id: 'swish',
                            title: 'Swish',
                            detail: 'Instant mobile payment',
                            brand: 'swish',
                          ),
                          const Divider(
                            height: 1,
                            indent: 62,
                            endIndent: 16,
                            color: _line,
                          ),
                          _paymentTile(
                            id: 'cash',
                            title: 'Cash',
                            detail: 'Pay the driver in cash',
                            brand: 'cash',
                          ),
                          for (final method in _extraMethods) ...[
                            const Divider(
                              height: 1,
                              indent: 62,
                              endIndent: 16,
                              color: _line,
                            ),
                            _paymentTile(
                              id: method['id']!,
                              title: method['title']!,
                              detail: method['detail']!,
                              brand: method['id']!,
                            ),
                          ],
                          const Divider(
                            height: 1,
                            indent: 62,
                            endIndent: 16,
                            color: _line,
                          ),
                          _actionTile(
                            icon: Icons.add_rounded,
                            title: 'Add payment method',
                            onTap: _openAddPaymentMethod,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    _sectionLabel('VOUCHERS'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: _actionTile(
                        icon: Icons.confirmation_number_outlined,
                        title: 'Vouchers unavailable',
                        onTap: _openVoucherForm,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: _muted,
                          size: 15,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Your payment preferences are protected and can be changed anytime.',
                            style: _style(
                              9.5,
                              weight: FontWeight.w400,
                              color: _muted,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Back',
            child: Material(
              color: _surface,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(Icons.arrow_back_rounded, color: _ink, size: 22),
                ),
              ),
            ),
          ),
          const Spacer(),
          Text('Payment', style: _style(13, weight: FontWeight.w600)),
          const Spacer(),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _profileSelector() {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _profileOption(
            label: 'Personal',
            icon: Icons.person_outline_rounded,
            selected: !_businessProfile,
            onTap: () => _selectProfile(false),
          ),
          _profileOption(
            label: 'Business',
            icon: Icons.business_center_outlined,
            selected: _businessProfile,
            onTap: () => _selectProfile(true),
          ),
        ],
      ),
    );
  }

  Widget _profileOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.055),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: selected ? _ink : _muted, size: 16),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: _style(
                    11.5,
                    weight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? _ink : _muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: _style(
        10,
        weight: FontWeight.w600,
        color: _muted,
      ).copyWith(letterSpacing: 1.25),
    );
  }

  Widget _paymentTile({
    required String id,
    required String title,
    required String detail,
    required String brand,
  }) {
    final selected = _selectedMethod == id;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectMethod(id),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              _brandMark(brand),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _style(12.5, weight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      selected ? 'Default for rides' : detail,
                      style: _style(
                        9.3,
                        weight: FontWeight.w400,
                        color: selected ? _accent : _muted,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? _ink : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? _ink : _line,
                    width: 1.4,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 15,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _brandMark(String brand) {
    Widget logo;
    Color background = Colors.white;

    if (brand == 'apple') {
      logo = SvgPicture.asset(
        'assets/images/apple_pay_brand.svg',
        fit: BoxFit.contain,
      );
    } else if (brand == 'google') {
      logo = Image.asset(
        excludeFromSemantics: true,
        'assets/images/google_pay_brand.png',
        fit: BoxFit.contain,
      );
    } else if (brand == 'paypal') {
      logo = Image.asset(
        excludeFromSemantics: true,
        AppAssets.paypal,
        fit: BoxFit.contain,
      );
    } else if (brand == 'klarna') {
      background = const Color(0xFFFFB3C7);
      logo = SvgPicture.asset(
        'assets/images/klarna_brand.svg',
        fit: BoxFit.contain,
      );
    } else if (brand == 'cards') {
      logo = Row(
        children: [
          Expanded(
            child: Image.asset(
              excludeFromSemantics: true,
              AppAssets.visa,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Image.asset(
              excludeFromSemantics: true,
              AppAssets.mastercard,
              fit: BoxFit.contain,
            ),
          ),
        ],
      );
    } else if (brand == 'swish') {
      logo = SvgPicture.asset(
        'assets/images/swish_brand.svg',
        fit: BoxFit.cover,
      );
    } else if (brand == 'wallet' || brand.startsWith('wallet')) {
      background = const Color(0xFF11181D);
      logo = const Icon(
        Icons.account_balance_wallet_rounded,
        color: Colors.white,
        size: 20,
      );
    } else if (brand == 'cash') {
      background = const Color(0xFFEEF6F0);
      logo = const Icon(
        Icons.payments_outlined,
        color: Color(0xFF1F7A4D),
        size: 20,
      );
    } else {
      logo = Image.asset(
        excludeFromSemantics: true,
        AppAssets.mastercard,
        fit: BoxFit.contain,
      );
    }

    return Container(
      width: 42,
      height: 38,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: background == Colors.white ? _line : background,
        ),
      ),
      child: brand == 'google'
          ? Transform.scale(scale: 1.18, child: logo)
          : brand == 'swish'
          ? ClipRRect(borderRadius: BorderRadius.circular(4), child: logo)
          : logo,
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Row(
            children: [
              Icon(icon, color: _ink, size: 21),
              const SizedBox(width: 17),
              Expanded(
                child: Text(title, style: _style(12, weight: FontWeight.w600)),
              ),
              const Icon(Icons.chevron_right_rounded, color: _muted, size: 21),
            ],
          ),
        ),
      ),
    );
  }
}
