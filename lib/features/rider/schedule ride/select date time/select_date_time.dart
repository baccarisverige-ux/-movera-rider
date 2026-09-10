import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ScheduleDateTimeSelector extends StatefulWidget {
  final VoidCallback onConfirm;
  final Widget body;

  const ScheduleDateTimeSelector({
    super.key,
    required this.body,
    required this.onConfirm,
  });

  @override
  State<ScheduleDateTimeSelector> createState() =>
      _ScheduleDateTimeSelectorState();
}

class _ScheduleDateTimeSelectorState extends State<ScheduleDateTimeSelector> {
  static const Color _ink = Color(0xFF17232B);
  static const Color _muted = Color(0xFF77848D);
  static const Color _accent = Color(0xFF2D6688);
  static const Color _accentSoft = Color(0xFFEAF3F7);
  static const Color _surface = Color(0xFFF6F8F9);
  static const Color _line = Color(0xFFE4E9EC);

  late DateTime _selectedDateTime;
  late final List<DateTime> _dates;
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;
  bool _pickupMode = true;

  @override
  void initState() {
    super.initState();
    final candidate = DateTime.now().add(const Duration(minutes: 30));
    final remainder = candidate.minute % 5;
    _selectedDateTime = candidate.add(
      Duration(minutes: remainder == 0 ? 0 : 5 - remainder),
    );
    _dates = List.generate(
      14,
      (index) {
        final date = DateTime.now().add(Duration(days: index));
        return DateTime(date.year, date.month, date.day);
      },
    );
    _hourController = FixedExtentScrollController(
      initialItem: _selectedDateTime.hour,
    );
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedDateTime.minute ~/ 5,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        _selectedDateTime.hour,
        _selectedDateTime.minute,
      );
    });
  }

  void _selectHour(int hour) {
    setState(() {
      _selectedDateTime = DateTime(
        _selectedDateTime.year,
        _selectedDateTime.month,
        _selectedDateTime.day,
        hour,
        _selectedDateTime.minute,
      );
    });
  }

  void _selectMinute(int index) {
    setState(() {
      _selectedDateTime = DateTime(
        _selectedDateTime.year,
        _selectedDateTime.month,
        _selectedDateTime.day,
        _selectedDateTime.hour,
        index * 5,
      );
    });
  }

  TextStyle _text(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = _ink,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = DateTime(
      _selectedDateTime.year,
      _selectedDateTime.month,
      _selectedDateTime.day,
    );
    final arrival = _pickupMode
        ? _selectedDateTime.add(const Duration(minutes: 20))
        : _selectedDateTime;
    final pickup = _pickupMode
        ? _selectedDateTime
        : _selectedDateTime.subtract(const Duration(minutes: 20));

    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _topBar(context),
                    const SizedBox(height: 20),
                    Text(
                      'Schedule your ride',
                      style: _text(28, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Choose the time that works best for your journey.',
                      style: _text(13, weight: FontWeight.w400, color: _muted),
                    ),
                    const SizedBox(height: 22),
                    _modeSelector(),
                    const SizedBox(height: 22),
                    Text(
                      'Choose a day',
                      style: _text(15, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _dateStrip(selectedDay),
                    const SizedBox(height: 22),
                    _timeCard(),
                    const SizedBox(height: 18),
                    _journeySummary(pickup, arrival),
                    const SizedBox(height: 18),
                    _policyCard(),
                  ],
                ),
              ),
            ),
            _continueArea(),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        Material(
          color: _surface,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () => Navigator.maybePop(context),
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.arrow_back_rounded, color: _ink, size: 23),
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: _accentSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: _accent, size: 17),
              const SizedBox(width: 7),
              Text(
                'Movera Reserve',
                style: _text(10.5, weight: FontWeight.w600, color: _accent),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modeSelector() {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          _modeButton(
            title: 'Pick up at',
            icon: Icons.my_location_rounded,
            selected: _pickupMode,
            onTap: () => setState(() => _pickupMode = true),
          ),
          _modeButton(
            title: 'Arrive by',
            icon: Icons.flag_rounded,
            selected: !_pickupMode,
            onTap: () => setState(() => _pickupMode = false),
          ),
        ],
      ),
    );
  }

  Widget _modeButton({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: _ink.withOpacity(0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: selected ? _accent : _muted),
                const SizedBox(width: 7),
                Text(
                  title,
                  style: _text(
                    12,
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

  Widget _dateStrip(DateTime selectedDay) {
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final date = _dates[index];
          final selected = date == selectedDay;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectDate(date),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 62,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? _accent : _surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? _accent : _line,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: _accent.withOpacity(0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 7),
                          ),
                        ]
                      : const [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      index == 0 ? 'Today' : DateFormat('EEE').format(date),
                      style: _text(
                        10,
                        weight: FontWeight.w500,
                        color: selected ? Colors.white70 : _muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('d').format(date),
                      style: _text(
                        20,
                        weight: FontWeight.w700,
                        color: selected ? Colors.white : _ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _timeCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: _accentSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.schedule_rounded, color: _accent, size: 19),
              ),
              const SizedBox(width: 10),
              Text('Choose a time', style: _text(14, weight: FontWeight.w600)),
              const Spacer(),
              Text(
                DateFormat('HH:mm').format(_selectedDateTime),
                style: _text(17, weight: FontWeight.w700, color: _accent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 132,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _line),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker.builder(
                        scrollController: _hourController,
                        itemExtent: 42,
                        useMagnifier: true,
                        magnification: 1.08,
                        selectionOverlay: const SizedBox.shrink(),
                        onSelectedItemChanged: _selectHour,
                        childCount: 24,
                        itemBuilder: (_, index) => Center(
                          child: Text(
                            index.toString().padLeft(2, '0'),
                            style: _text(21, weight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    Text(':', style: _text(21, weight: FontWeight.w700, color: _accent)),
                    Expanded(
                      child: CupertinoPicker.builder(
                        scrollController: _minuteController,
                        itemExtent: 42,
                        useMagnifier: true,
                        magnification: 1.08,
                        selectionOverlay: const SizedBox.shrink(),
                        onSelectedItemChanged: _selectMinute,
                        childCount: 12,
                        itemBuilder: (_, index) => Center(
                          child: Text(
                            (index * 5).toString().padLeft(2, '0'),
                            style: _text(21, weight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _journeySummary(DateTime pickup, DateTime arrival) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_rounded, color: _accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _pickupMode ? 'Estimated arrival' : 'Estimated pickup',
              style: _text(11, weight: FontWeight.w500, color: _muted),
            ),
          ),
          Text(
            DateFormat('HH:mm').format(_pickupMode ? arrival : pickup),
            style: _text(15, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _policyCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accentSoft.withOpacity(0.65),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined, color: _accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Flexible cancellation before a driver is assigned. Final terms are shown before booking.',
              style: _text(10.5, weight: FontWeight.w400, color: _muted)
                  .copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _continueArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: widget.onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              'Continue',
              style: _text(14, weight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
