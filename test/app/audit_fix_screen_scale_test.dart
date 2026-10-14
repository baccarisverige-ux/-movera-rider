import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/app/screen_scale.dart';

/// UI-9: ScreenUtil scale factors stay inside [0.85, 1.25] on every axis,
/// and phones between the bounds (the 390x844 reference included) scale
/// exactly as they did with the old 375x812 setup.
void main() {
  Future<(double, double, double)> factorsAt(
    WidgetTester tester,
    Size viewport,
  ) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MoveraScreenUtilInit(builder: (_, __) => const SizedBox()),
    );
    await tester.pump();
    final su = ScreenUtil();
    return (su.scaleWidth, su.scaleHeight, su.scaleText);
  }

  testWidgets('the 390x844 reference keeps its old factors', (tester) async {
    final (w, h, t) = await factorsAt(tester, const Size(390, 844));
    expect(w, 390 / 375);
    expect(h, 844 / 812);
    expect(t, 844 / 812);
  });

  testWidgets('a 1280x800 desktop window no longer scales widths 3.4x', (
    tester,
  ) async {
    final (w, h, t) = await factorsAt(tester, const Size(1280, 800));
    expect(w, closeTo(moveraMaxScale, 1e-9));
    expect(h, closeTo(800 / 812, 1e-9));
    expect(t, closeTo(800 / 812, 1e-9));
  });

  testWidgets('844x390 landscape stays inside the bounds', (tester) async {
    final (w, h, _) = await factorsAt(tester, const Size(844, 390));
    expect(w, closeTo(moveraMaxScale, 1e-9));
    expect(h, closeTo(moveraMinScale, 1e-9));
  });

  testWidgets('short phones scale heights by their real height', (
    tester,
  ) async {
    // The old splitScreenMode floor treated every screen as 700 px tall.
    final (_, h, _) = await factorsAt(tester, const Size(375, 760));
    expect(h, closeTo(760 / 812, 1e-9));
    final (_, small, _) = await factorsAt(tester, const Size(320, 568));
    expect(small, closeTo(moveraMinScale, 1e-9));
  });

  testWidgets('a window resize rebuilds with new bounds', (tester) async {
    await factorsAt(tester, const Size(390, 844));
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pump();
    await tester.pump();
    expect(ScreenUtil().scaleWidth, closeTo(moveraMaxScale, 1e-9));
  });
}
