import 'package:flutter/material.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:flip_card/flip_card.dart';
import 'package:movera/widgets/custom_textfield.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class RideCompletedAddTip extends StatefulWidget {
  const RideCompletedAddTip({super.key});

  @override
  State<RideCompletedAddTip> createState() => _RideCompletedAddTipState();
}

class _RideCompletedAddTipState extends State<RideCompletedAddTip> {
  List<String> tips = ["\$1", "\$2", "\$5"];
  int? selectedTipIndex; // Track which tip is selected
  List<GlobalKey<FlipCardState>> flipCardKeys =
      []; // Keys to control flip cards

  @override
  void initState() {
    super.initState();
    // Initialize flip card keys
    for (int i = 0; i < tips.length; i++) {
      flipCardKeys.add(GlobalKey<FlipCardState>());
    }
  }

  void selectTip(int index) {
    setState(() {
      // If clicking the same tip, deselect it
      if (selectedTipIndex == index) {
        selectedTipIndex = null;
        flipCardKeys[index].currentState?.toggleCard();
      } else {
        // If there was a previously selected tip, flip it back
        if (selectedTipIndex != null) {
          flipCardKeys[selectedTipIndex!].currentState?.toggleCard();
        }

        // Select new tip
        selectedTipIndex = index;
        flipCardKeys[index].currentState?.toggleCard();
      }
    });
  }

  String? customTip;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: TextWidget(
            text: "Add a tip for Marle",
            color: AppColor.title,
            fontSize: 16,
            fontWeight: fwSemiBold,
          ),
        ),
        15.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < tips.length; i++) ...[
              GestureDetector(
                onTap: () => selectTip(i),
                child: FlipCard(
                  key: flipCardKeys[i],
                  flipOnTouch: false, // Disable default flip behavior
                  front: flipCard(
                    tip: tips[i],
                    isFront: true,
                    isSelected: selectedTipIndex == i,
                  ),
                  back: flipCard(
                    tip: tips[i],
                    isFront: false,
                    isSelected: selectedTipIndex == i,
                  ),
                ),
              ),
              if (i < tips.length - 1) 18.width,
            ],
          ],
        ),

        31.height,
        if (customTip == null)
          TextButton(
            onPressed: () async {
              final result = await showDialog<String>(
                context: context,
                builder: (BuildContext context) {
                  return AddCustomTipDiaglog();
                },
              );

              if (result != null) {
                setState(() {
                  customTip = result; // save tip
                });
              }
            },
            child: TextWidget(
              text: "Add another amount",
              color: const Color(0xff007AFF),
              fontSize: 14,
              fontWeight: fwMedium,
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: ResSize.h * 44,
                decoration: BoxDecoration(
                  color: Color(0xff00C7BE),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Color(0xff555555).withOpacity(0.12),
                      blurRadius: 10,
                      spreadRadius: 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: ResSize.w * 16),
                  child: Row(
                    children: [
                      TextWidget(
                        text: "Tip amount: $customTip",
                        fontSize: 14,
                        fontWeight: fwSemiBold,
                        color: AppColor.whiteText,
                      ),
                      8.width,
                      InkWell(
                        onTap: () {
                          setState(() {
                            customTip = null; // 👈 remove custom tip
                          });
                        },
                        child: Container(
                          height: ResSize.h * 21,
                          width: ResSize.w * 21,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColor.white, width: 2),
                          ),
                          child: Icon(
                            Icons.close,
                            color: AppColor.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget flipCard({String? tip, bool? isFront, bool isSelected = false}) {
    return Container(
      height: ResSize.h * 70,
      width: ResSize.w * 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFront! ? Colors.transparent : Color(0xff00C7BE),
        border: isFront
            ? Border.all(
                color: isSelected ? Color(0xff00C7BE) : AppColor.border,
                width: isSelected ? 2.0 : 0.5,
              )
            : Border.all(color: Colors.transparent, width: 0),
      ),
      child: Center(
        child: TextWidget(
          text: tip,
          color: isFront ? AppColor.title : AppColor.whiteText,
          fontSize: 24,
          fontWeight: fwSemiBold,
        ),
      ),
    );
  }

  void showTipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddCustomTipDiaglog();
      },
    );
  }
}

// ignore: must_be_immutable
class AddCustomTipDiaglog extends StatelessWidget {
  AddCustomTipDiaglog({super.key});
  TextEditingController tipController = TextEditingController(text: "\$3.50");
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      elevation: 0, // No shadow
      backgroundColor:
          Colors.transparent, // Background is a transparent overlay
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Make the column as small as possible
        children: <Widget>[
          // Top section of the dialog with the "Add Tip" title and close button
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 15.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Spacer(), // Pushes the title to the center
                TextWidget(
                  text: "Add Tip",
                  color: AppColor.title,
                  fontSize: 20,
                  fontWeight: fwSemiBold,
                ),
                Spacer(), // Pushes the close button to the right
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop(); // Closes the dialog
                  },
                  child: Container(
                    height: ResSize.h * 24,
                    width: ResSize.w * 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColor.black, width: 2),
                    ),
                    child: Icon(Icons.close, color: AppColor.black, size: 16),
                  ),
                ),
              ],
            ),
          ),
          24.height,
          Center(
            child: SizedBox(
              width: ResSize.w * 130,
              child: customTextfield(
                keyboardType: TextInputType.number,
                borderColor: Colors.transparent,
                borderWidth: 0,
                borderRadius: 0,
                controller: tipController,
                contentHorizPadding: 0,
                contentVertPadding: 0,
                fontSize: 40,
                textColor: AppColor.black,
                fillColor: Colors.transparent,
              ),
            ),
          ),

          38.height, // Spacing
          // "SET TIP" button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Handle the action for setting the tip
                Navigator.of(context).pop(tipController.text.toString());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff00C7BE), // Button color
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0.0), // Button corners
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: TextWidget(
                text: "SET TIP",
                fontSize: 16,
                fontWeight: fwSemiBold,
                color: AppColor.whiteText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
