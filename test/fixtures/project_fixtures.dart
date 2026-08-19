// ═══════════════════════════════════════════════════════════════
// 🛠️ Test Fixtures — Estructuras de proyecto para tests
// ═══════════════════════════════════════════════════════════════

import 'dart:io';

/// Crea un proyecto Flutter de prueba en un directorio temporal
Directory createFlutterProject(Directory dir) {
  // pubspec.yaml
  File('${dir.path}/pubspec.yaml').writeAsStringSync('''
name: test_flutter_app
description: A Flutter test app
version: 1.0.0

environment:
  sdk: ^3.10.0

dependencies:
  flutter:
    sdk: flutter

flutter:
  uses-material-design: true
''');

  // main.dart
  File('${dir.path}/main.dart').writeAsStringSync('''
import 'package:flutter/material.dart';
void main() => runApp(const MyApp());
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  Widget build(BuildContext context) => MaterialApp(home: Scaffold(body: Text('Hello')));
}
''');

  // README.md
  File('${dir.path}/README.md').writeAsStringSync('''# Test App

## Autor
Test

## 💬 Una nota personal del autor
<details>
<summary>🇪🇸 Español</summary>
Texto en español
</details>
<details>
<summary>🇬🇧 English</summary>
English text
</details>
<details>
<summary>🇧🇷 Português</summary>
Texto em português
</details>

## 💖 Apoya el proyecto
PayPal

## Licencia
MIT

## About
Test app
''');

  // LICENSE
  File('${dir.path}/LICENSE').writeAsStringSync('MIT License');

  // analysis_options.yaml
  File('${dir.path}/analysis_options.yaml').writeAsStringSync('include: package:flutter_lints/flutter.yaml');

  // lib/
  Directory('${dir.path}/lib').createSync();
  File('${dir.path}/lib/main.dart').writeAsStringSync('void main() {}');
  Directory('${dir.path}/test').createSync();
  File('${dir.path}/test/widget_test.dart').writeAsStringSync('void main() {}');

  return dir;
}

/// Crea un proyecto Node.js de prueba
Directory createNodeProject(Directory dir) {
  File('${dir.path}/package.json').writeAsStringSync('''
{
  "name": "test-node-package",
  "description": "A Node.js test package",
  "version": "1.0.0"
}
''');
  File('${dir.path}/package-lock.json').writeAsStringSync('{}');
  File('${dir.path}/README.md').writeAsStringSync('# Test Node Package');
  return dir;
}

/// Crea una web HTML de prueba
Directory createWebProject(Directory dir) {
  File('${dir.path}/index.html').writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>Test</title></head><body><h1>Hello</h1></body></html>
''');
  return dir;
}

/// Crea un proyecto con estructura iOS (Info.plist)
Directory createIOSProject(Directory dir) {
  createFlutterProject(dir);
  Directory('${dir.path}/ios/Runner').createSync(recursive: true);
  File('${dir.path}/ios/Runner/Info.plist').writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Test</string>
</dict>
</plist>
''');
  return dir;
}

/// Crea un proyecto con .env (peligroso, para tests de seguridad)
Directory createProjectWithSecrets(Directory dir) {
  createFlutterProject(dir);
  File('${dir.path}/.env').writeAsStringSync('API_KEY=12345');
  File('${dir.path}/google-services.json').writeAsStringSync('{"project_info":{}}');
  return dir;
}

/// Crea un proyecto esqueleto (mínimo)
Directory createSkeletonProject(Directory dir) {
  File('${dir.path}/pubspec.yaml').writeAsStringSync('name: skeleton');
  return dir;
}

/// Crea universe.json de prueba
Directory createWithUniverse(Directory dir) {
  File('${dir.path}/universe.json').writeAsStringSync('''
{
  "version": 1,
  "lastUpdated": "2026-05-16",
  "pillars": {
    "herramientas": { "label": "Herramientas Dev", "color": "#FF8F00", "emoji": "🔧" }
  },
  "projects": []
}
''');
  return dir;
}

/// Limpia un directorio temporal
void cleanTempDir(Directory dir) {
  try {
    dir.deleteSync(recursive: true);
  } catch (_) {}
}
