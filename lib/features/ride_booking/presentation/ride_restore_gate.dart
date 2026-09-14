import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:movera_rider/app/navigator_key.dart';
import 'package:movera_rider/core/debug/web_qa_hooks.dart';
import 'package:movera_rider/core/web/web_overlay.dart';
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
    _lockHomeIfRoot();
  }

  void _lockHomeIfRoot() {
    final nav = moveraNavigatorKey.currentState;
    final atRoot = nav == null || !nav.canPop();
    final home =
        RideRestoreCoordinator.instance.showing == RestoredSurface.home;
    setWebHomeLock(atRoot && home);
  }

  @override
  void initState() {
    super.initState();
    reportRestoreSurface('hold');
    RideRestoreCoordinator.instance.onReplaceRoot = show;
    RideRestoreCoordinator.instance.root().then((page) {
      if (!mounted) return;
      setState(() => _child = page);
      _lockHomeIfRoot();
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
    final child =
        _child ??
        const ColoredBox(color: Color(0xFFFFFFFF), child: SizedBox.expand());
    return PopScope(
      canPop: !kIsWeb,
      child: child,
    );
  }
}
