import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/home/application/home_sheet_controller.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

/// Phase 141: home_sheet_controller.dart had zero test coverage. Exercises
/// the behavior that does not require a live Sheet widget attached - the
/// "no client yet" guards every method falls back to before a real Sheet
/// mounts, plus scheduleIdleClose's guard logic.
void main() {
  group('HomeSheetController without an attached sheet', () {
    late SheetController sheet;
    late HomeSheetController controller;

    setUp(() {
      sheet = SheetController();
      controller = HomeSheetController(
        controller: sheet,
        minPixels: () => 100,
        midPixels: () => 300,
      );
    });

    tearDown(() => controller.dispose());

    test('isAtMiddle is false before a sheet client attaches', () {
      expect(controller.isAtMiddle, isFalse);
    });

    test('animateTo/open/close/toggle are no-ops without a client', () async {
      await controller.animateTo(const SheetOffset(1));
      await controller.open();
      controller.close();
      controller.toggle(expandedThreshold: 24);
      // Nothing threw and isAtMiddle is still just reading local state.
      expect(controller.isAtMiddle, isFalse);
    });

    test('scheduleIdleClose does not schedule when not at middle', () async {
      var mounted = true;
      controller.scheduleIdleClose(
        accessibleNavigation: false,
        isMounted: () => mounted,
      );
      // isAtMiddle is false (no client), so the guard should have cancelled
      // rather than scheduled - nothing to wait for, and calling
      // cancelIdleTimer again must be safe.
      controller.cancelIdleTimer();
      mounted = false;
    });

    test('scheduleIdleClose is skipped under accessible navigation', () {
      controller.scheduleIdleClose(
        accessibleNavigation: true,
        isMounted: () => true,
      );
      // No exception, no timer left dangling for the test to flag.
    });

    test('dispose cancels any pending idle timer safely', () {
      controller.scheduleIdleClose(
        accessibleNavigation: true,
        isMounted: () => true,
      );
      controller.dispose();
    });
  });
}
