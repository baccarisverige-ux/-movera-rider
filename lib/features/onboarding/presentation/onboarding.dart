import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/home/presentation/home.dart';

class OnboardingGate extends StatelessWidget {
  const OnboardingGate({super.key});
  @override
  Widget build(BuildContext context) {
    AppScope.instance.onboarding.markSeen();
    return const Home();
  }
}
