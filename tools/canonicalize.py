from pathlib import Path
import shutil
import re
import subprocess

PKG = "movera_rider"
BUNDLE = "com.movera.rider"
ROOT = Path(".")


def move(src: str, dst: str) -> None:
    source = Path(src)
    target = Path(dst)
    if not source.exists():
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        raise RuntimeError(f"Target already exists: {target}")
    shutil.move(str(source), str(target))


# Feature-first architecture while preserving screen implementation and assets.
move("lib/constants", "lib/core/constants")
move("lib/services", "lib/core/services")
move("lib/models", "lib/shared/models")
move("lib/widgets", "lib/shared/widgets")
move("lib/presentation/common", "lib/shared/presentation")
move("lib/presentation/rider", "lib/features/rider")

# These are genuinely used by Rider in the original combined app.
move("lib/presentation/driver/my wallet", "lib/features/rider/my wallet")
move("lib/presentation/driver/promotions", "lib/features/rider/promotions")

# Remove the rest of the old combined app presentation tree.
shutil.rmtree("lib/presentation", ignore_errors=True)

replacements = [
    ("package:movera/constants/", f"package:{PKG}/core/constants/"),
    ("package:movera/services/", f"package:{PKG}/core/services/"),
    ("package:movera/models/", f"package:{PKG}/shared/models/"),
    ("package:movera/widgets/", f"package:{PKG}/shared/widgets/"),
    ("package:movera/presentation/common/", f"package:{PKG}/shared/presentation/"),
    ("package:movera/presentation/rider/", f"package:{PKG}/features/rider/"),
    ("package:movera/presentation/driver/my%20wallet/", f"package:{PKG}/features/rider/my%20wallet/"),
    ("package:movera/presentation/driver/promotions/", f"package:{PKG}/features/rider/promotions/"),
    ("package:movera/", f"package:{PKG}/"),
]

candidates = list(Path("lib").rglob("*.dart")) + list(Path("test").rglob("*.dart"))
for dart in candidates:
    if not dart.is_file():
        continue
    text = dart.read_text(errors="ignore")
    for old, new in replacements:
        text = text.replace(old, new)
    dart.write_text(text)

# Preserve Rider onboarding behavior (onboarding -> Rider Home), but remove Driver coupling.
onboarding = Path("lib/shared/presentation/onboarding/onboarding.dart")
text = onboarding.read_text()
text = "\n".join(
    line
    for line in text.splitlines()
    if "presentation/driver/" not in line
    and "features/rider/auth/starter/starter.dart" not in line
) + "\n"
onboarding.write_text(text)

# Independent Dart/native identity.
pubspec = Path("pubspec.yaml")
text = pubspec.read_text()
text = re.sub(r"^name:\s*movera\s*$", "name: movera_rider", text, flags=re.M)
text = re.sub(
    r"^description:.*$",
    'description: "Movera Rider mobile application."',
    text,
    count=1,
    flags=re.M,
)
pubspec.write_text(text)

gradle = Path("android/app/build.gradle.kts")
if gradle.exists():
    gradle.write_text(gradle.read_text().replace("com.example.movera", BUNDLE))

activities = [p for p in Path("android/app/src/main").rglob("MainActivity.kt") if p.is_file()]
if activities:
    source = activities[0]
    content = re.sub(
        r"^package\s+[\w.]+",
        f"package {BUNDLE}",
        source.read_text(),
        count=1,
        flags=re.M,
    )
    target = Path("android/app/src/main/kotlin/com/movera/rider/MainActivity.kt")
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content)
    if source.resolve() != target.resolve():
        source.unlink()

pbx = Path("ios/Runner.xcodeproj/project.pbxproj")
if pbx.exists():
    pbx.write_text(pbx.read_text().replace("com.example.movera", BUNDLE))

manifest = Path("android/app/src/main/AndroidManifest.xml")
if manifest.exists():
    content = re.sub(
        r'android:label="[^"]*"',
        'android:label="Movera Rider"',
        manifest.read_text(),
        count=1,
    )
    manifest.write_text(content)

info = Path("ios/Runner/Info.plist")
if info.exists():
    info.write_text(info.read_text().replace("<string>movera</string>", "<string>Movera Rider</string>"))

web = Path("web/index.html")
if web.exists():
    web.write_text(web.read_text().replace("<title>movera</title>", "<title>Movera Rider</title>"))

# Transport-only files are not part of the future source tree.
for zip_file in ROOT.glob("rider-part-*.zip"):
    if zip_file.is_file():
        zip_file.unlink()

for workflow in [
    ".github/workflows/extract-uploaded-parts.yml",
    ".github/workflows/architecture-audit.yml",
    ".github/workflows/canonicalize-architecture.yml",
    ".github/workflows/debug-canonicalize.yml",
]:
    Path(workflow).unlink(missing_ok=True)

# Replace the stale Flutter counter template test with a Movera smoke test.
Path("test").mkdir(exist_ok=True)
Path("test/widget_test.dart").write_text(
    """import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/main.dart';

void main() {
  testWidgets('Movera Rider root app mounts', (tester) async {
    await tester.pumpWidget(const MoveraApp());
    expect(find.byType(MoveraApp), findsOneWidget);
  });
}
"""
)

Path("README.md").write_text(
    """# Movera Rider

This repository is the canonical source of truth for the **Movera Rider** Flutter application.

## Architecture

- `lib/features/rider/` — Rider-only product features and screens
- `lib/core/constants/` — app-wide constants, colors, assets and typography configuration
- `lib/core/services/` — Rider app services
- `lib/shared/models/` — Rider data models used across features
- `lib/shared/widgets/` — reusable UI widgets
- `lib/shared/presentation/` — shared presentation such as splash/onboarding
- `assets/` — original app assets, kept intact

Driver application code belongs only in the separate Movera Driver repository.
Generated Flutter/Gradle files, temporary upload ZIPs, and build output are intentionally not source-controlled.
"""
)

Path(".gitignore").write_text(
    """# Dart / Flutter generated
.dart_tool/
.packages
.pub/
build/
.flutter-plugins
.flutter-plugins-dependencies
**/doc/api/

# Android generated/local
android/.gradle/
android/local.properties
android/**/GeneratedPluginRegistrant.java

# iOS/macOS generated
ios/Flutter/ephemeral/
ios/Flutter/Generated.xcconfig
ios/Flutter/flutter_export_environment.sh
macos/Flutter/ephemeral/

# Desktop generated
linux/flutter/ephemeral/
linux/flutter/generated_plugin_registrant.cc
linux/flutter/generated_plugin_registrant.h
linux/flutter/generated_plugins.cmake
windows/flutter/ephemeral/
windows/flutter/generated_plugin_registrant.cc
windows/flutter/generated_plugin_registrant.h
windows/flutter/generated_plugins.cmake

# IDE / OS
.idea/
*.iml
.DS_Store
.vscode/
"""
)

Path(".github/workflows").mkdir(parents=True, exist_ok=True)
Path(".github/workflows/ci.yml").write_text(
    """name: Movera Rider CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
permissions:
  contents: read
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter analyze --no-fatal-infos --no-fatal-warnings
      - run: flutter test
      - run: flutter build web --release
      - run: flutter build apk --debug
"""
)

# Untrack files now classified as generated by the canonical ignore rules.
ignored = subprocess.check_output(
    ["git", "ls-files", "-ci", "--exclude-standard"], text=True
).splitlines()
for name in ignored:
    path = Path(name)
    if path.is_dir():
        shutil.rmtree(path, ignore_errors=True)
    else:
        path.unlink(missing_ok=True)

# Final architecture invariants.
remaining_driver_imports = []
for dart in Path("lib").rglob("*.dart"):
    if not dart.is_file():
        continue
    content = dart.read_text(errors="ignore")
    if "/presentation/driver/" in content or "/features/driver/" in content:
        remaining_driver_imports.append(str(dart))
if remaining_driver_imports:
    raise RuntimeError(f"Driver coupling remains: {remaining_driver_imports}")
if Path("lib/presentation").exists() or Path("lib/features/driver").exists():
    raise RuntimeError("Old combined presentation tree remains")
