import 'package:flutter/material.dart';
import 'package:movera_rider/features/home/presentation/home.dart';
import 'package:movera_rider/features/onboarding/application/onboarding_controller.dart';

class OnboardingGate extends StatelessWidget {
  const OnboardingGate({super.key});
  @override
  Widget build(BuildContext context) {
    OnboardingController().markSeen();
    return const Home();
  }
}
