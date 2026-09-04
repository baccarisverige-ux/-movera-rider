import os, shutil, re, pathlib
variant=os.environ['VARIANT']
root=pathlib.Path('.')
other=pathlib.Path('/tmp/other')
missing_side='driver' if variant=='rider' else 'passenger'
src=other/'lib'/'presentation'/missing_side
dst=root/'lib'/'presentation'/missing_side
if dst.exists(): shutil.rmtree(dst)
shutil.copytree(src,dst)
if variant=='rider':
    src_on=other/'lib'/'presentation'/'common'/'onboarding'/'onboarding.dart'
    dst_on=root/'lib'/'presentation'/'common'/'onboarding'/'onboarding.dart'
    dst_on.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(src_on,dst_on)

mains=list((root/'android/app/src/main/kotlin').rglob('MainActivity.kt'))
main_text='package com.example.riding_app\n\nimport io.flutter.embedding.android.FlutterActivity\n\nclass MainActivity : FlutterActivity()\n'
orig_main=root/'android/app/src/main/kotlin/com/example/riding_app/MainActivity.kt'
orig_main.parent.mkdir(parents=True,exist_ok=True)
orig_main.write_text(main_text,encoding='utf-8')
for p in mains:
    if p.resolve()!=orig_main.resolve():
        try:p.unlink()
        except:pass
mv=root/'android/app/src/main/kotlin/com/movera'
if mv.exists(): shutil.rmtree(mv)

for p in root.rglob('*'):
    if not p.is_file() or '.git' in p.parts or '.github' in p.parts: continue
    try:s=p.read_text(encoding='utf-8')
    except Exception: continue
    s=s.replace('package:movera_rider/','package:riding_app/')
    s=s.replace('package:movera_driver/','package:riding_app/')
    s=s.replace('name: movera_rider','name: riding_app').replace('name: movera_driver','name: riding_app')
    s=s.replace('description: "Movera Rider taxi app."','description: "A new Flutter project."')
    s=s.replace('description: "Movera Driver taxi app."','description: "A new Flutter project."')
    s=s.replace('Movera Rider','Riding App').replace('Movera Driver','Riding App')
    s=s.replace('movera_rider','riding_app').replace('movera_driver','riding_app')
    s=s.replace('com.movera.rider','com.example.riding_app').replace('com.movera.driver','com.example.riding_app')
    p.write_text(s,encoding='utf-8')

p=root/'android/app/src/main/AndroidManifest.xml'; s=p.read_text(); s=s.replace('android:label="Riding App"','android:label="riding_app"'); p.write_text(s)
p=root/'ios/Runner.xcodeproj/project.pbxproj'; s=p.read_text(); s=re.sub(r'com\.movera(?:Rider|Driver)(\.RunnerTests)?',lambda m:'com.example.ridingApp'+(m.group(1) or ''),s); p.write_text(s)
p=root/'ios/Runner/Info.plist'; s=p.read_text(); s=s.replace('<key>CFBundleName</key>\n\t<string>Riding App</string>','<key>CFBundleName</key>\n\t<string>riding_app</string>'); p.write_text(s)

p=root/'lib/main.dart'; s=p.read_text(); s=s.replace('MoveraRiderApp','RidingApp').replace('MoveraDriverApp','RidingApp'); p.write_text(s)

p=root/'lib/presentation/common/onboarding/onboarding.dart'; s=p.read_text()
if "presentation/passenger/auth/login/login.dart" not in s:
    s=s.replace("import 'package:riding_app/presentation/driver/auth/login/login.dart';", "import 'package:riding_app/presentation/driver/auth/login/login.dart';\nimport 'package:riding_app/presentation/passenger/auth/login/login.dart';")
s=s.replace('class OnboardingScreen extends StatefulWidget {\n  const OnboardingScreen({super.key});', 'class OnboardingScreen extends StatefulWidget {\n  final bool isDriver;\n  const OnboardingScreen({super.key, required this.isDriver});')
s=s.replace('''                                  Navigator.pushReplacement(\n                                    context,\n                                    BottomToTopTransition(DriverLogin()),\n                                  );''','''                                  widget.isDriver\n                                      ? Navigator.pushReplacement(\n                                          context,\n                                          BottomToTopTransition(DriverLogin()),\n                                        )\n                                      : Navigator.pushReplacement(\n                                          context,\n                                          BottomToTopTransition(\n                                            PassengerLogin(),\n                                          ),\n                                        );''')
s=s.replace('''                              Navigator.pushReplacement(\n                                context,\n                                BottomToTopTransition(DriverLogin()),\n                              );''','''                              widget.isDriver\n                                  ? Navigator.pushReplacement(\n                                      context,\n                                      BottomToTopTransition(DriverLogin()),\n                                    )\n                                  : Navigator.pushReplacement(\n                                      context,\n                                      BottomToTopTransition(PassengerLogin()),\n                                    );''')
p.write_text(s)

p=root/'lib/presentation/common/splash/splash.dart'; s=p.read_text()
s=s.replace("import 'package:riding_app/presentation/passenger/auth/login/login.dart';", "import 'package:riding_app/presentation/common/onboarding/onboarding.dart';")
s=s.replace('RightToLeftTransition(const PassengerLogin())', f'RightToLeftTransition(const OnboardingScreen(isDriver: {str(variant=="driver").lower()}))')
s=s.replace('RightToLeftTransition(const OnboardingScreen())', f'RightToLeftTransition(const OnboardingScreen(isDriver: {str(variant=="driver").lower()}))')
s=s.replace('RightToLeftTransition(const OnboardingScreen(isDriver: true))', f'RightToLeftTransition(const OnboardingScreen(isDriver: {str(variant=="driver").lower()}))')
p.write_text(s)

p=root/'lib/widgets/responsive_size.dart'; s=p.read_text(); s=s.replace('double screenHorizPadding = ScreenUtil().setWidth(16);','double get screenHorizPadding => ScreenUtil().setWidth(16);'); p.write_text(s)

(root/'README.md').write_text('''# riding_app\n\nA new Flutter project.\n\n## Getting Started\n\nThis project is a starting point for a Flutter application.\n\nA few resources to get you started if this is your first Flutter project:\n\n- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)\n- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)\n\nFor help getting started with Flutter development, view the\n[online documentation](https://docs.flutter.dev/), which offers tutorials,\nsamples, guidance on mobile development, and a full API reference.\n''',encoding='utf-8')
(root/'test/widget_test.dart').write_text('''// This is a basic Flutter widget test.\n//\n// To perform an interaction with a widget in your test, use the WidgetTester\n// utility in the flutter_test package. For example, you can send tap and scroll\n// gestures. You can also use WidgetTester to find child widgets in the widget\n// tree, read text, and verify that the values of widget properties are correct.\n\nimport 'package:flutter/material.dart';\nimport 'package:flutter_test/flutter_test.dart';\n\nimport 'package:riding_app/main.dart';\n\nvoid main() {\n  testWidgets('Counter increments smoke test', (WidgetTester tester) async {\n    // Build our app and trigger a frame.\n    await tester.pumpWidget(const RidingApp());\n\n    // Verify that our counter starts at 0.\n    expect(find.text('0'), findsOneWidget);\n    expect(find.text('1'), findsNothing);\n\n    // Tap the '+' icon and trigger a frame.\n    await tester.tap(find.byIcon(Icons.add));\n    await tester.pump();\n\n    // Verify that our counter has incremented.\n    expect(find.text('0'), findsNothing);\n    expect(find.text('1'), findsOneWidget);\n  });\n}\n''',encoding='utf-8')
p=root/'web/index.html'; s=p.read_text(); s=s.replace('Riding App taxi app.','A new Flutter project.').replace('apple-mobile-web-app-title" content="Riding App"','apple-mobile-web-app-title" content="riding_app"').replace('<title>Riding App</title>','<title>riding_app</title>'); p.write_text(s)
p=root/'web/manifest.json'; s=p.read_text(); s=s.replace('"name": "Riding App"','"name": "riding_app"').replace('"short_name": "Riding App"','"short_name": "riding_app"').replace('"description": "Riding App taxi app."','"description": "A new Flutter project."'); p.write_text(s)
