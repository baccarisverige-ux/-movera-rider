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
  static const Color _ink = Color(0xFF17232B);
  static const Color _muted = Color(0xFF77848D);
  static const Color _accent = Color(0xFF344A53);
  static const Color _accentSoft = Color(0xFFF0F3F4);
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
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _topBar(context),
                    const SizedBox(height: 14),
                    Text(
                      'Choose date & time',
                      style: _text(23, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Select when your driver should be ready.',
                      style: _text(11.5, weight: FontWeight.w400, color: _muted),
                    ),
                    const SizedBox(height: 16),
                    _modeSelector(),
                    const SizedBox(height: 17),
                    Text(
                      'DATE',
                      style: _text(10, weight: FontWeight.w600, color: _muted)
                          .copyWith(letterSpacing: 1.3),
                    ),
                    const SizedBox(height: 9),
                    _dateStrip(selectedDay),
                    const SizedBox(height: 16),
                    _timeCard(),
                    const SizedBox(height: 12),
                    _journeySummary(pickup, arrival),
                    const SizedBox(height: 10),
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
            onTap: widget.onBack ?? () => Navigator.maybePop(context),
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.arrow_back_rounded, color: _ink, size: 21),
            ),
          ),
        ),
        const Spacer(),
        Text(
          'DATE & TIME',
          style: _text(
            10,
            weight: FontWeight.w600,
            color: _muted,
          ).copyWith(letterSpacing: 1.4),
        ),
      ],
    );
  }

  Widget _modeSelector() {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(15),
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
        color: selected ? _ink : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: _ink.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: selected ? Colors.white : _muted),
                const SizedBox(width: 7),
                Text(
                  title,
                  style: _text(
                    11.5,
                    weight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? Colors.white : _muted,
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
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = _dates[index];
          final selected = date == selectedDay;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectDate(date),
              borderRadius: BorderRadius.circular(17),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 55,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? _accent : _surface,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: selected ? _accent : _line,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: _ink.withOpacity(0.14),
                            blurRadius: 11,
                            offset: const Offset(0, 5),
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
                        9,
                        weight: FontWeight.w500,
                        color: selected ? Colors.white70 : _muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('d').format(date),
                      style: _text(
                        18,
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: _accentSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.schedule_rounded, color: _accent, size: 17),
              ),
              const SizedBox(width: 10),
              Text('TIME', style: _text(10, weight: FontWeight.w600, color: _muted).copyWith(letterSpacing: 1.3)),
              const Spacer(),
              Text(
                DateFormat('HH:mm').format(_selectedDateTime),
                style: _text(15, weight: FontWeight.w700, color: _ink),
              ),
            ],
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 108,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _line),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker.builder(
                        scrollController: _hourController,
                        itemExtent: 38,
                        useMagnifier: true,
                        magnification: 1.05,
                        selectionOverlay: const SizedBox.shrink(),
                        onSelectedItemChanged: _selectHour,
                        childCount: 24,
                        itemBuilder: (_, index) => Center(
                          child: Text(
                            index.toString().padLeft(2, '0'),
                            style: _text(19, weight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    Text(':', style: _text(19, weight: FontWeight.w700, color: _ink)),
                    Expanded(
                      child: CupertinoPicker.builder(
                        scrollController: _minuteController,
                        itemExtent: 38,
                        useMagnifier: true,
                        magnification: 1.05,
                        selectionOverlay: const SizedBox.shrink(),
                        onSelectedItemChanged: _selectMinute,
                        childCount: 12,
                        itemBuilder: (_, index) => Center(
                          child: Text(
                            (index * 5).toString().padLeft(2, '0'),
                            style: _text(19, weight: FontWeight.w600),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_rounded, color: _accent, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _pickupMode ? 'Estimated arrival' : 'Estimated pickup',
              style: _text(10.5, weight: FontWeight.w500, color: _muted),
            ),
          ),
          Text(
            DateFormat('HH:mm').format(_pickupMode ? arrival : pickup),
            style: _text(14, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _policyCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: _accentSoft.withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined, color: _accent, size: 18),
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
      padding: const EdgeInsets.fromLTRB(18, 9, 18, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: widget.onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: _ink,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
