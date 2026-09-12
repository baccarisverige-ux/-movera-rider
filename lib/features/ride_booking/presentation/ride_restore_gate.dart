import 'package:flutter/material.dart';
import 'package:movera_rider/features/ride_booking/application/ride_restore_coordinator.dart';

class RideRestoreGate extends StatefulWidget {
  const RideRestoreGate({super.key});

  @override
  State<RideRestoreGate> createState() => _RideRestoreGateState();
}

class _RideRestoreGateState extends State<RideRestoreGate> {
  Widget? _child;

  @override
  void initState() {
    super.initState();
    RideRestoreCoordinator.instance.root().then((page) {
      if (!mounted) return;
      setState(() => _child = page);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _child ??
        const ColoredBox(
          color: Color(0xFFFFFFFF),
          child: SizedBox.expand(),
        );
  }
}
