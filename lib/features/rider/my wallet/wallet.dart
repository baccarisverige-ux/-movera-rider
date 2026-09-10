import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const Color _ink = Color(0xFF171C1F);
  static const Color _muted = Color(0xFF7B8388);
  static const Color _surface = Color(0xFFF4F5F4);
  static const Color _line = Color(0xFFE6E8E7);
  static const Color _accent = Color(0xFF356879);

  bool _businessProfile = false;
  String _selectedMethod = 'apple';
  String? _voucherCode;
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
    final prefs = await SharedPreferences.getInstance();
    final savedMethods = prefs.getString('movera_payment_methods');
    if (!mounted) return;
    setState(() {
      _selectedMethod =
          prefs.getString('movera_default_payment') ?? 'apple';
      _businessProfile =
          prefs.getBool('movera_payment_business') ?? false;
      _voucherCode = prefs.getString('movera_voucher_code');
      if (savedMethods != null) {
        try {
          final decoded = jsonDecode(savedMethods) as List<dynamic>;
          _extraMethods = decoded
              .whereType<Map>()
              .map(
                (item) => item.map(
                  (key, value) =>
                      MapEntry(key.toString(), value.toString()),
                ),
              )
              .toList();
        } catch (_) {
          _extraMethods = [];
        }
      }
    });
  }

  Future<void> _savePaymentSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'movera_default_payment',
      _selectedMethod,
    );
    await prefs.setBool(
      'movera_payment_business',
      _businessProfile,
    );
    await prefs.setString(
      'movera_payment_methods',
      jsonEncode(_extraMethods),
    );
    if (_voucherCode == null || _voucherCode!.isEmpty) {
      await prefs.remove('movera_voucher_code');
    } else {
      await prefs.setString('movera_voucher_code', _voucherCode!);
    }
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
    final method = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.28),
      builder: (sheetContext) {
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
                    Text(
                      'Add payment method',
                      style: _style(17, weight: FontWeight.w600),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                      color: _muted,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                _addMethodChoice(
                  brand: 'cards',
                  title: 'Debit or credit card',
                  subtitle: 'Visa, Mastercard or Amex',
                  onTap: () => Navigator.pop(sheetContext, 'card'),
                ),
                _addMethodChoice(
                  brand: 'paypal',
                  title: 'PayPal',
                  subtitle: 'Connect your PayPal account',
                  onTap: () => Navigator.pop(sheetContext, 'paypal'),
                ),
                _addMethodChoice(
                  brand: 'klarna',
                  title: 'Klarna',
                  subtitle: 'Pay now or later when available',
                  onTap: () => Navigator.pop(sheetContext, 'klarna'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || method == null) return;
    if (method == 'card') {
      await _openCardForm();
    } else {
      _addProvider(method);
    }
  }

  Widget _addMethodChoice({
    required String brand,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
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
                    Text(
                      subtitle,
                      style: _style(
                        9.5,
                        weight: FontWeight.w400,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _muted,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addProvider(String provider) {
    final title = provider == 'paypal' ? 'PayPal' : 'Klarna';
    final exists = _extraMethods.any((item) => item['id'] == provider);
    setState(() {
      if (!exists) {
        _extraMethods.add({
          'id': provider,
          'title': title,
          'detail': 'Connected',
        });
      }
      _selectedMethod = provider;
    });
    _savePaymentSettings();
  }

  Future<void> _openCardForm() async {
    final numberController = TextEditingController();
    final nameController = TextEditingController();
    final expiryController = TextEditingController();
    final cvcController = TextEditingController();

    final lastFour = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.28),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final digits = numberController.text.replaceAll(
              RegExp(r'[^0-9]'),
              '',
            );
            final canSave = digits.length >= 12 &&
                nameController.text.trim().isNotEmpty &&
                expiryController.text.trim().isNotEmpty &&
                cvcController.text.trim().length >= 3;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
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
                          Text(
                            'Add a card',
                            style: _style(17, weight: FontWeight.w600),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close_rounded),
                            color: _muted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _cardField(
                        controller: numberController,
                        label: 'Card number',
                        hint: '0000 0000 0000 0000',
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setSheetState(() {}),
                      ),
                      const SizedBox(height: 10),
                      _cardField(
                        controller: nameController,
                        label: 'Name on card',
                        hint: 'Cardholder name',
                        onChanged: (_) => setSheetState(() {}),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _cardField(
                              controller: expiryController,
                              label: 'Expiry',
                              hint: 'MM/YY',
                              keyboardType: TextInputType.datetime,
                              onChanged: (_) => setSheetState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _cardField(
                              controller: cvcController,
                              label: 'CVC',
                              hint: '000',
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              onChanged: (_) => setSheetState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: canSave
                              ? () => Navigator.pop(
                                    sheetContext,
                                    digits.substring(digits.length - 4),
                                  )
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _ink,
                            disabledBackgroundColor: _ink.withOpacity(0.16),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Save card',
                            style: _style(
                              13,
                              weight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            color: _muted,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Only the last four digits are stored here.',
                            style: _style(
                              9,
                              weight: FontWeight.w400,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    numberController.dispose();
    nameController.dispose();
    expiryController.dispose();
    cvcController.dispose();

    if (!mounted || lastFour == null) return;
    final id = 'card_$lastFour';
    setState(() {
      _extraMethods.removeWhere((item) => item['id'] == id);
      _extraMethods.add({
        'id': id,
        'title': 'Card ending $lastFour',
        'detail': 'Debit or credit card',
      });
      _selectedMethod = id;
    });
    _savePaymentSettings();
  }

  Widget _cardField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      style: _style(12.5, weight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: _surface,
        labelStyle: _style(10, color: _muted),
        hintStyle: _style(11, weight: FontWeight.w400, color: _muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _ink, width: 1),
        ),
      ),
    );
  }

  Future<void> _openVoucherForm() async {
    final controller = TextEditingController(text: _voucherCode ?? '');
    final code = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.28),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final valid = controller.text.trim().length >= 4;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
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
                      const SizedBox(height: 18),
                      Text(
                        'Add voucher',
                        style: _style(17, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Enter your Movera voucher code.',
                        style: _style(
                          10.5,
                          weight: FontWeight.w400,
                          color: _muted,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _cardField(
                        controller: controller,
                        label: 'Voucher code',
                        hint: 'Enter code',
                        onChanged: (_) => setSheetState(() {}),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: valid
                              ? () => Navigator.pop(
                                    sheetContext,
                                    controller.text.trim().toUpperCase(),
                                  )
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _ink,
                            disabledBackgroundColor: _ink.withOpacity(0.16),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Apply voucher',
                            style: _style(
                              13,
                              weight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    controller.dispose();
    if (code == null || !mounted) return;
    setState(() => _voucherCode = code);
    _savePaymentSettings();
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
                      style: _style(
                        27,
                        weight: FontWeight.w700,
                        height: 1.18,
                      ),
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
                            color: Colors.black.withOpacity(0.035),
                            blurRadius: 22,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
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
                      child: _voucherCode == null
                          ? _actionTile(
                              icon: Icons.confirmation_number_outlined,
                              title: 'Add voucher code',
                              onTap: _openVoucherForm,
                            )
                          : ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 4,
                              ),
                              leading: const Icon(
                                Icons.confirmation_number_outlined,
                                color: _ink,
                              ),
                              title: Text(
                                _voucherCode!,
                                style: _style(
                                  12.5,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Voucher applied',
                                style: _style(
                                  9.5,
                                  weight: FontWeight.w400,
                                  color: _muted,
                                ),
                              ),
                              trailing: IconButton(
                                onPressed: () {
                                  setState(() => _voucherCode = null);
                                  _savePaymentSettings();
                                },
                                icon: const Icon(Icons.close_rounded),
                                color: _muted,
                                iconSize: 19,
                              ),
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
          Material(
            color: _surface,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: _ink,
                  size: 22,
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Payment',
            style: _style(13, weight: FontWeight.w600),
          ),
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
                        color: Colors.black.withOpacity(0.055),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: selected ? _ink : _muted,
                  size: 16,
                ),
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
        'assets/images/google_pay_brand.png',
        fit: BoxFit.contain,
      );
    } else if (brand == 'paypal') {
      logo = Image.asset(
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
              AppAssets.visa,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Image.asset(
              AppAssets.mastercard,
              fit: BoxFit.contain,
            ),
          ),
        ],
      );
    } else {
      logo = Image.asset(
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
                child: Text(
                  title,
                  style: _style(12, weight: FontWeight.w600),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _muted,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
