import os, shutil, pathlib
variant=os.environ['VARIANT']
root=pathlib.Path('.')
other=pathlib.Path('/tmp/other')

# Restore the missing opposite-side source from the counterpart repository.
missing_side='driver' if variant=='rider' else 'passenger'
src=other/'lib'/'presentation'/missing_side
dst=root/'lib'/'presentation'/missing_side
if dst.exists(): shutil.rmtree(dst)
shutil.copytree(src,dst)

# Rider was missing the original shared onboarding; seed it from Driver.
if variant=='rider':
    src_on=other/'lib'/'presentation'/'common'/'onboarding'/'onboarding.dart'
    dst_on=root/'lib'/'presentation'/'common'/'onboarding'/'onboarding.dart'
    dst_on.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(src_on,dst_on)

# Reverse every package/app rename introduced by the previous split.
for p in root.rglob('*'):
    if not p.is_file() or '.git' in p.parts or '.github' in p.parts: continue
    try: s=p.read_text(encoding='utf-8')
    except Exception: continue
    s=s.replace('package:riding_app/','package:riding_app/')
    s=s.replace('package:riding_app/','package:riding_app/')
    s=s.replace('name: riding_app','name: riding_app').replace('name: riding_app','name: riding_app')
    s=s.replace('description: "A new Flutter project."','description: "A new Flutter project."')
    s=s.replace('description: "A new Flutter project."','description: "A new Flutter project."')
    s=s.replace('Riding App','Riding App').replace('Riding App','Riding App')
    s=s.replace('riding_app','riding_app').replace('riding_app','riding_app')
    p.write_text(s,encoding='utf-8')

# Restore original main app class.
p=root/'lib/main.dart'; s=p.read_text(); s=s.replace('MoveraRiderApp','RidingApp').replace('MoveraDriverApp','RidingApp'); p.write_text(s)

# Restore the original shared onboarding branching exactly.
p=root/'lib/presentation/common/onboarding/onboarding.dart'; s=p.read_text()
if "presentation/passenger/auth/login/login.dart" not in s:
    s=s.replace("import 'package:riding_app/presentation/driver/auth/login/login.dart';", "import 'package:riding_app/presentation/driver/auth/login/login.dart';\nimport 'package:riding_app/presentation/passenger/auth/login/login.dart';")
s=s.replace('class OnboardingScreen extends StatefulWidget {\n  const OnboardingScreen({super.key});','class OnboardingScreen extends StatefulWidget {\n  final bool isDriver;\n  const OnboardingScreen({super.key, required this.isDriver});')
s=s.replace('''                                  Navigator.pushReplacement(\n                                    context,\n                                    BottomToTopTransition(DriverLogin()),\n                                  );''','''                                  widget.isDriver\n                                      ? Navigator.pushReplacement(\n                                          context,\n                                          BottomToTopTransition(DriverLogin()),\n                                        )\n                                      : Navigator.pushReplacement(\n                                          context,\n                                          BottomToTopTransition(\n                                            PassengerLogin(),\n                                          ),\n                                        );''')
s=s.replace('''                              Navigator.pushReplacement(\n                                context,\n                                BottomToTopTransition(DriverLogin()),\n                              );''','''                              widget.isDriver\n                                  ? Navigator.pushReplacement(\n                                      context,\n                                      BottomToTopTransition(DriverLogin()),\n                                    )\n                                  : Navigator.pushReplacement(\n                                      context,\n                                      BottomToTopTransition(PassengerLogin()),\n                                    );''')
p.write_text(s)

# Original splash, with only the repo role changed.
p=root/'lib/presentation/common/splash/splash.dart'; s=p.read_text()
s=s.replace("import 'package:riding_app/presentation/passenger/auth/login/login.dart';","import 'package:riding_app/presentation/common/onboarding/onboarding.dart';")
role='true' if variant=='driver' else 'false'
s=s.replace('RightToLeftTransition(const PassengerLogin())',f'RightToLeftTransition(const OnboardingScreen(isDriver: {role}))')
s=s.replace('RightToLeftTransition(const OnboardingScreen())',f'RightToLeftTransition(const OnboardingScreen(isDriver: {role}))')
s=s.replace('RightToLeftTransition(const OnboardingScreen(isDriver: true))',f'RightToLeftTransition(const OnboardingScreen(isDriver: {role}))')
p.write_text(s)

# Web-only startup crash fix; does not alter layout/design.
p=root/'lib/widgets/responsive_size.dart'; s=p.read_text(); s=s.replace('double screenHorizPadding = ScreenUtil().setWidth(16);','double get screenHorizPadding => ScreenUtil().setWidth(16);'); p.write_text(s)

# Restore original visible web metadata.
p=root/'web/index.html'; s=p.read_text(); s=s.replace('Riding App taxi app.','A new Flutter project.').replace('apple-mobile-web-app-title" content="Riding App"','apple-mobile-web-app-title" content="riding_app"').replace('<title>Riding App</title>','<title>riding_app</title>'); p.write_text(s)
p=root/'web/manifest.json'; s=p.read_text(); s=s.replace('"name": "Riding App"','"name": "riding_app"').replace('"short_name": "Riding App"','"short_name": "riding_app"').replace('"description": "Riding App taxi app."','"description": "A new Flutter project."'); p.write_text(s)
