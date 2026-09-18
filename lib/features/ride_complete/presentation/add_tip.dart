import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/ride_complete/application/ride_complete_controller.dart';
import 'package:movera_rider/shared/accessibility/a11y.dart';
import 'package:movera_rider/shared/design_system/movera_empty_state.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';

class RideCompletedAddTip extends StatefulWidget {
  const RideCompletedAddTip({super.key, this.controller});

  final RideCompleteController? controller;

  @override
  State<RideCompletedAddTip> createState() => _RideCompletedAddTipState();
}

class _RideCompletedAddTipState extends State<RideCompletedAddTip> {
  late final RideCompleteController _ctl =
      widget.controller ?? RideCompleteController();
  late final List<String> _amounts = _ctl.tips();
  late final String? _driverName = _ctl.driver()?.name;
  String? _selected;

  void _choose(String amount) {
    setState(() => _selected = _selected == amount ? null : amount);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: TextWidget(
            text: _driverName == null
                ? 'Tip your driver'
                : 'Tip $_driverName',
            color: AppColor.title,
            fontSize: 16,
            fontWeight: fwSemiBold,
          ),
        ),
        if (_amounts.isEmpty)
          const MoveraEmptyState(
            icon: Icons.volunteer_activism_outlined,
            title: 'Tips unavailable',
            message: "Tipping isn't available in this build.",
            compact: true,
          )
        else ...[
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final amount in _amounts)
                _TipChip(
                  amount: amount,
                  selected: _selected == amount,
                  onTap: () => _choose(amount),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextWidget(
            text: _selected == null
                ? 'Tips go to your driver in full.'
                : '$_selected added for your driver.',
            color: AppColor.subtitle,
            fontSize: 12,
            fontWeight: fwMedium,
          ),
        ],
      ],
    );
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip({
    required this.amount,
    required this.selected,
    required this.onTap,
  });

  final String amount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2D5878);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Tip $amount',
      child: Material(
        color: selected ? accent : Colors.white,
        borderRadius: BorderRadius.circular(A11y.minTap / 2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(A11y.minTap / 2),
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 84,
              minHeight: A11y.minTap,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(A11y.minTap / 2),
              border: Border.all(
                color: selected ? accent : AppColor.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: TextWidget(
              text: amount,
              color: selected ? AppColor.whiteText : AppColor.title,
              fontSize: 15,
              fontWeight: fwSemiBold,
            ),
          ),
        ),
      ),
    );
  }
}
