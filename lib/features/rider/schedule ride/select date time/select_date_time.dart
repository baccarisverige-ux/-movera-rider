import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ScheduleDateTimeSelector extends StatefulWidget {
  final VoidCallback onConfirm;
  final VoidCallback? onBack;
  final Widget body;

  const ScheduleDateTimeSelector({
    super.key,
    required this.body,
    required this.onConfirm,
    this.onBack,
  });

  @override
  State<ScheduleDateTimeSelector> createState() =>
      _ScheduleDateTimeSelectorState();
}

class _ScheduleDateTimeSelectorState extends State<ScheduleDateTimeSelector> {
  static const Color _ink = Color(0xFF15191C);
  static const Color _muted = Color(0xFF7B8287);
  static const Color _surface = Color(0xFFF5F5F3);
  static const Color _line = Color(0xFFE7E7E4);

  late DateTime _selectedDateTime;
  bool _pickupMode = true;

  @override
  void initState() {
    super.initState();
    final candidate = DateTime.now().add(const Duration(minutes: 30));
    final remainder = candidate.minute % 5;
    _selectedDateTime = candidate.add(
      Duration(minutes: remainder == 0 ? 0 : 5 - remainder),
    );
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

  Future<void> _chooseDate() async {
    var draftDate = _selectedDateTime;
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.28),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
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
                    const SizedBox(height: 13),
                    Row(
                      children: [
                        Text(
                          'Select date',
                          style: _style(16, weight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('d MMM yyyy').format(draftDate),
                          style: _style(
                            11,
                            weight: FontWeight.w500,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      height: 305,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: _ink,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: _ink,
                          ),
                          datePickerTheme: const DatePickerThemeData(
                            backgroundColor: Colors.white,
                            headerBackgroundColor: Colors.white,
                            headerForegroundColor: _ink,
                            surfaceTintColor: Colors.transparent,
                          ),
                        ),
                        child: CalendarDatePicker(
                          initialDate: draftDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          onDateChanged: (date) {
                            setSheetState(() => draftDate = date);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: _sheetAction(
                            label: 'Cancel',
                            filled: false,
                            onTap: () => Navigator.pop(sheetContext),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _sheetAction(
                            label: 'Done',
                            filled: true,
                            onTap: () =>
                                Navigator.pop(sheetContext, draftDate),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (result == null || !mounted) return;
    setState(() {
      _selectedDateTime = DateTime(
        result.year,
        result.month,
        result.day,
        _selectedDateTime.hour,
        _selectedDateTime.minute,
      );
    });
  }

  Future<void> _chooseTime() async {
    var draftHour = _selectedDateTime.hour;
    var draftMinute = (_selectedDateTime.minute ~/ 5) * 5;
    final hourController = FixedExtentScrollController(
      initialItem: draftHour,
    );
    final minuteController = FixedExtentScrollController(
      initialItem: draftMinute ~/ 5,
    );

    final result = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.28),
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            height: 300,
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _line,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Text(
                      'Select time',
                      style: _style(16, weight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      '24-hour',
                      style: _style(
                        10.5,
                        weight: FontWeight.w500,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoPicker.builder(
                              scrollController: hourController,
                              itemExtent: 40,
                              useMagnifier: true,
                              magnification: 1.04,
                              selectionOverlay: const SizedBox.shrink(),
                              childCount: 24,
                              onSelectedItemChanged: (value) {
                                draftHour = value;
                              },
                              itemBuilder: (_, index) => Center(
                                child: Text(
                                  index.toString().padLeft(2, '0'),
                                  style: _style(
                                    20,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Text(
                            ':',
                            style: _style(20, weight: FontWeight.w700),
                          ),
                          Expanded(
                            child: CupertinoPicker.builder(
                              scrollController: minuteController,
                              itemExtent: 40,
                              useMagnifier: true,
                              magnification: 1.04,
                              selectionOverlay: const SizedBox.shrink(),
                              childCount: 12,
                              onSelectedItemChanged: (value) {
                                draftMinute = value * 5;
                              },
                              itemBuilder: (_, index) => Center(
                                child: Text(
                                  (index * 5).toString().padLeft(2, '0'),
                                  style: _style(
                                    20,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: _sheetAction(
                        label: 'Cancel',
                        filled: false,
                        onTap: () => Navigator.pop(sheetContext),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _sheetAction(
                        label: 'Done',
                        filled: true,
                        onTap: () => Navigator.pop(
                          sheetContext,
                          TimeOfDay(
                            hour: draftHour,
                            minute: draftMinute,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    hourController.dispose();
    minuteController.dispose();
    if (result == null || !mounted) return;
    setState(() {
      _selectedDateTime = DateTime(
        _selectedDateTime.year,
        _selectedDateTime.month,
        _selectedDateTime.day,
        result.hour,
        result.minute,
      );
    });
  }

  Widget _sheetAction({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 44,
      child: Material(
        color: filled ? _ink : _surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Text(
              label,
              style: _style(
                12,
                weight: FontWeight.w600,
                color: filled ? Colors.white : _ink,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estimatedTime = _pickupMode
        ? _selectedDateTime.add(const Duration(minutes: 20))
        : _selectedDateTime.subtract(const Duration(minutes: 20));

    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(context),
                    const SizedBox(height: 30),
                    Text(
                      'When should we\npick you up?',
                      style: _style(
                        29,
                        weight: FontWeight.w700,
                        height: 1.16,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'Choose a date and time for your scheduled ride.',
                      style: _style(
                        12.5,
                        weight: FontWeight.w400,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _modeSelector(),
                    const SizedBox(height: 18),
                    _selectionCard(),
                    const SizedBox(height: 18),
                    _estimateRow(estimatedTime),
                    const SizedBox(height: 25),
                    Text(
                      'You can cancel without a fee before a driver is assigned. Final terms are shown before booking.',
                      style: _style(
                        10.5,
                        weight: FontWeight.w400,
                        color: _muted,
                        height: 1.55,
                      ),
                    ),

                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
              child: SizedBox(
                width: double.infinity,
                height: 118,
                child: Image.asset(
                  'assets/images/schedule_timeline_white.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            _continueButton(),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Material(
          color: _surface,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: widget.onBack ?? () => Navigator.maybePop(context),
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
          'Schedule ride',
          style: _style(12, weight: FontWeight.w600),
        ),
        const Spacer(),
        const SizedBox(width: 42),
      ],
    );
  }

  Widget _modeSelector() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _modeOption(
            label: 'Pick up at',
            selected: _pickupMode,
            onTap: () => setState(() => _pickupMode = true),
          ),
          _modeOption(
            label: 'Arrive by',
            selected: !_pickupMode,
            onTap: () => setState(() => _pickupMode = false),
          ),
        ],
      ),
    );
  }

  Widget _modeOption({
    required String label,
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: Text(
              label,
              style: _style(
                12,
                weight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? _ink : _muted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _selectionRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: DateFormat('EEE, d MMMM').format(_selectedDateTime),
            onTap: _chooseDate,
          ),
          const Divider(height: 1, indent: 58, endIndent: 16, color: _line),
          _selectionRow(
            icon: Icons.schedule_rounded,
            label: 'Time',
            value: DateFormat('HH:mm').format(_selectedDateTime),
            onTap: _chooseTime,
          ),
        ],
      ),
    );
  }

  Widget _selectionRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          child: Row(
            children: [
              Icon(icon, color: _ink, size: 20),
              const SizedBox(width: 18),
              Text(
                label,
                style: _style(11, weight: FontWeight.w500, color: _muted),
              ),
              const Spacer(),
              Text(
                value,
                style: _style(13, weight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: _muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _estimateRow(DateTime time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_rounded, color: _ink, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _pickupMode ? 'Estimated arrival' : 'Estimated pickup',
              style: _style(11, weight: FontWeight.w500, color: _muted),
            ),
          ),
          Text(
            DateFormat('HH:mm').format(time),
            style: _style(13, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _continueButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: widget.onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: _ink,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            child: Text(
              'Continue',
              style: _style(
                14,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
