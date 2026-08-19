import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:erbolamm_studio/features/publisher/presentation/widgets/store_metadata_auditor_widget.dart';
import 'package:erbolamm_studio/services/project_monitor.dart';

void main() {
  group('StoreMetadataAuditorWidget Tests', () {
    late Directory tempDir;
    late Directory inboxDir;
    late Directory projDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('store_auditor_test_');
      inboxDir = Directory(p.join(tempDir.path, 'INBOX'))..createSync();
      projDir = Directory(p.join(inboxDir.path, 'demo_app'))..createSync();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets('Renders correctly and shows legacy size warning when found', (tester) async {
      final screenshotsDir = Directory(p.join(projDir.path, 'promo', 'screenshots', '5.5_inch'))
        ..createSync(recursive: true);
      File(p.join(screenshotsDir.path, 'screen1.png')).writeAsStringSync('dummy');

      final monitor = ProjectMonitor(basePath: tempDir.path);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreMetadataAuditorWidget(monitor: monitor),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Auditoría de Metadatos & Release Notes'), findsOneWidget);
      expect(find.textContaining('Detectada carpeta/archivo legacy "5.5"'), findsOneWidget);
      expect(find.text('Copiar para iOS'), findsOneWidget);
      expect(find.text('Copiar Todo (Android)'), findsOneWidget);
    });
  });
}
