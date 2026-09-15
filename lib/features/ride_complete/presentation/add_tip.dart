import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/shared/design_system/movera_empty_state.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';

class RideCompletedAddTip extends StatelessWidget {
  const RideCompletedAddTip({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: TextWidget(
            text: 'Tip your driver',
            color: AppColor.title,
            fontSize: 16,
            fontWeight: fwSemiBold,
          ),
        ),
        const MoveraEmptyState(
          icon: Icons.volunteer_activism_outlined,
          title: 'Tips unavailable',
          message: "Tipping isn't available in this build.",
          compact: true,
        ),
      ],
    );
  }
}
