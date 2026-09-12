import 'package:flutter/material.dart';
import 'package:movera_rider/features/ride_booking/application/ride_restore_coordinator.dart';

class RideRestoreGate extends StatefulWidget {
  const RideRestoreGate({super.key});

  static final gateKey = GlobalKey<RideRestoreGateState>();

  static void show(Widget page) {
    gateKey.currentState?.show(page);
  }

  @override
  State<RideRestoreGate> createState() => RideRestoreGateState();
}

class RideRestoreGateState extends State<RideRestoreGate> {
  Widget? _child;

  void show(Widget page) {
    if (!mounted) return;
    setState(() => _child = page);
  }

  @override
  void initState() {
    super.initState();
    RideRestoreCoordinator.instance.onReplaceRoot = show;
    RideRestoreCoordinator.instance.root().then((page) {
      if (!mounted) return;
      setState(() => _child = page);
    });
  }

  @override
  void dispose() {
    if (identical(RideRestoreCoordinator.instance.onReplaceRoot, show)) {
      RideRestoreCoordinator.instance.onReplaceRoot = null;
    }
    super.dispose();
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
