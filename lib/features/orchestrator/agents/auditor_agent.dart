// ═══════════════════════════════════════════════════════════════
// ✅ Agente 3 — Auditor de Requisitos
// ═══════════════════════════════════════════════════════════════
// Verifica todos los requisitos de INBOX.md Pasos 3–3.9:
//   - Campos obligatorios según tipo de proyecto
//   - README completo con bloque final estándar
//   - Privacidad iOS (SKAdNetwork, ATT) si aplica
//   - Seguridad npm/Node si aplica
//   - Skills oficiales Dart/Flutter si aplica
//   - Checklist privacidad/interno si aplica
// ═══════════════════════════════════════════════════════════════

import 'dart:io';

import '../domain/agent_interface.dart';

/// Resultado de una verificación individual
class AuditCheck {
  final String id;
  final String label;
  final bool passed;
  final String? detail;
  final String severity; // 'required', 'recommended', 'optional'

  const AuditCheck({
    required this.id,
    required this.label,
    required this.passed,
    this.detail,
    this.severity = 'required',
  });
}

/// Resultado completo de la auditoría
class AuditResult {
  final List<AuditCheck> checks;
  final int passedCount;
  final int failedCount;
  final int totalCount;
  final bool canPublish;
  final String summary;

  const AuditResult({
    required this.checks,
    required this.passedCount,
    required this.failedCount,
    required this.totalCount,
    required this.canPublish,
    required this.summary,
  });
}

/// Agente 3: Audita el proyecto contra los requisitos de INBOX.md
class AuditorAgent implements AgentInterface {
  @override
  String get agentId => 'auditor';
  @override
  String get agentName => 'Auditor de Requisitos';
  @override
  String get inboxStep => 'Pasos 3–3.9';

  @override
  Future<bool> canExecute(String projectPath) async {
    return Directory(projectPath).existsSync();
  }

  @override
  Future<AgentOutput> execute(String projectPath) async {
    final checks = <AuditCheck>[];
    final dir = Directory(projectPath);
    final files = _listFiles(dir);
    final names = files
        .map((f) => f.path.split(Platform.pathSeparator).last)
        .toSet();
    final allPaths = files.map((f) => f.path).toSet();

    // ── 3.1 Determinar tipo de proyecto ──
    final projectType = _detectProjectType(names, allPaths);
    checks.add(
      AuditCheck(
        id: 'type-detected',
        label: 'Tipo de proyecto detectado',
        passed: projectType != 'desconocido',
        detail: projectType,
        severity: 'required',
      ),
    );

    // ── 3.2 Campos obligatorios según tipo ──
    checks.addAll(_checkRequiredFields(projectType, names, allPaths));

    // ── 3.5 README obligatorio ──
    checks.addAll(await _checkReadme(files, projectPath));

    // ── 3.6 Privacidad iOS (solo si es Flutter con iOS) ──
    if (projectType.contains('Flutter') || projectType.contains('flutter')) {
      checks.addAll(_checkIOSPrivacy(names, allPaths));
    }

    // ── 3.7 Seguridad npm/Node ──
    if (names.contains('package.json')) {
      checks.addAll(_checkNpmSecurity(files, allPaths));
    }

    // ── 3.8 Skills Dart/Flutter ──
    if (names.contains('pubspec.yaml')) {
      checks.addAll(_checkFlutterSkills(names, allPaths));
    }

    // ── 3.9 Proyecto privado ──
    checks.addAll(_checkPrivateProject(files, names));

    // ── Calcular resultados ──
    final passed = checks.where((c) => c.passed).length;
    final failed = checks.where((c) => !c.passed).length;
    final canPublish = checks
        .where((c) => c.severity == 'required')
        .every((c) => c.passed);

    final result = AuditResult(
      checks: checks,
      passedCount: passed,
      failedCount: failed,
      totalCount: checks.length,
      canPublish: canPublish,
      summary: canPublish
          ? '✅ $passed/$passed requisitos cumplidos. Listo para publicar.'
          : '⚠️ $failed requisitos obligatorios fallan. Revisar antes de publicar.',
    );

    return AgentOutput(
      agentId: agentId,
      success: true,
      summary: result.summary,
      data: {
        'canPublish': result.canPublish,
        'passed': result.passedCount,
        'failed': result.failedCount,
        'total': result.totalCount,
        'checks': result.checks
            .map(
              (c) => {
                'id': c.id,
                'label': c.label,
                'passed': c.passed,
                'detail': c.detail,
                'severity': c.severity,
              },
            )
            .toList(),
      },
    );
  }

  // ─── Utils ───

  List<File> _listFiles(Directory dir) {
    final files = <File>[];
    try {
      dir.listSync(recursive: true).forEach((e) {
        if (e is File) {
          final path = e.path;
          if (!path.contains('/build/') &&
              !path.contains('/.git/') &&
              !path.contains('/node_modules/') &&
              !path.contains('/.dart_tool/')) {
            files.add(e);
          }
        }
      });
    } catch (_) {}
    return files;
  }

  String _detectProjectType(Set<String> names, Set<String> paths) {
    if (names.contains('pubspec.yaml')) {
      bool hasFlutter = false;
      for (final p in paths) {
        if (p.endsWith('pubspec.yaml')) {
          try {
            if (File(p).readAsStringSync().contains('flutter:')) {
              hasFlutter = true;
            }
          } catch (_) {}
        }
      }
      if (hasFlutter) return 'app_flutter';
      return 'paquete_dart';
    }
    if (names.contains('package.json')) return 'node_package';
    if (names.contains('index.html')) return 'web_html';
    return 'desconocido';
  }

  // ─── Paso 3: Campos obligatorios ───

  List<AuditCheck> _checkRequiredFields(
    String type,
    Set<String> names,
    Set<String> paths,
  ) {
    final checks = <AuditCheck>[];

    // README
    checks.add(
      AuditCheck(
        id: 'readme-exists',
        label: 'README.md',
        passed: names.contains('README.md'),
        severity: 'required',
      ),
    );

    // LICENSE
    checks.add(
      AuditCheck(
        id: 'license-exists',
        label: 'LICENSE',
        passed: names.contains('LICENSE'),
        severity: 'required',
      ),
    );

    // CHANGELOG
    checks.add(
      AuditCheck(
        id: 'changelog-exists',
        label: 'CHANGELOG.md',
        passed: names.contains('CHANGELOG.md'),
        severity: 'recommended',
      ),
    );

    // Según tipo
    switch (type) {
      case 'app_flutter':
        checks.add(
          AuditCheck(
            id: 'has-main-dart',
            label: 'main.dart (entry point)',
            passed: names.contains('main.dart'),
            severity: 'required',
          ),
        );
        checks.add(
          AuditCheck(
            id: 'has-pubspec',
            label: 'pubspec.yaml con nombre y descripción',
            passed: _checkPubspecHasName(paths),
            severity: 'required',
          ),
        );
        break;

      case 'paquete_dart':
        checks.add(
          AuditCheck(
            id: 'has-pubspec',
            label: 'pubspec.yaml con nombre, descripción, versión',
            passed: _checkPubspecHasName(paths),
            severity: 'required',
          ),
        );
        checks.add(
          AuditCheck(
            id: 'has-lib',
            label: 'Carpeta lib/ con código',
            passed: paths.any(
              (p) => p.contains('/lib/') && p.endsWith('.dart'),
            ),
            severity: 'required',
          ),
        );
        break;

      case 'node_package':
        checks.add(
          AuditCheck(
            id: 'package-json-valid',
            label: 'package.json con name y description',
            passed: _checkPackageJson(paths),
            severity: 'required',
          ),
        );
        break;

      case 'web_html':
        checks.add(
          AuditCheck(
            id: 'index-html-valid',
            label: 'index.html con title y meta tags',
            passed: names.contains('index.html'),
            severity: 'required',
          ),
        );
        break;
    }

    return checks;
  }

  bool _checkPubspecHasName(Set<String> paths) {
    for (final p in paths) {
      if (p.endsWith('pubspec.yaml')) {
        try {
          final content = File(p).readAsStringSync();
          return content.contains('name:') && content.contains('description:');
        } catch (_) {}
      }
    }
    return false;
  }

  bool _checkPackageJson(Set<String> paths) {
    for (final p in paths) {
      if (p.endsWith('package.json')) {
        try {
          final content = File(p).readAsStringSync();
          return content.contains('"name"') &&
              content.contains('"description"');
        } catch (_) {}
      }
    }
    return false;
  }

  // ─── Paso 3.5: README completo ───

  Future<List<AuditCheck>> _checkReadme(
    List<File> files,
    String projectPath,
  ) async {
    final checks = <AuditCheck>[];

    final readmeFile = files
        .where((f) => f.path.endsWith('README.md'))
        .firstOrNull;

    if (readmeFile == null) {
      checks.add(
        AuditCheck(
          id: 'readme-sections',
          label: 'README con secciones: Autor, Apoya, Licencia, About',
          passed: false,
          detail: 'No existe README.md',
          severity: 'required',
        ),
      );
      return checks;
    }

    try {
      final content = readmeFile.readAsStringSync();

      // Verificar secciones obligatorias
      final hasAutor = content.contains('## Autor');
      final hasNotaPersonal = content.contains('## 💬 Una nota personal');
      final hasApoya = content.contains('## 💖 Apoya');
      final hasLicencia = content.contains('## Licencia');
      final hasAbout = content.contains('## About');
      final hasMultiLang =
          content.contains('<summary>🇪🇸') &&
          content.contains('<summary>🇬🇧') &&
          content.contains('<summary>🇧🇷');

      final sections = [
        if (!hasAutor) '## Autor',
        if (!hasNotaPersonal) '## 💬 Una nota personal',
        if (!hasApoya) '## 💖 Apoya',
        if (!hasLicencia) '## Licencia',
        if (!hasAbout) '## About',
      ];

      checks.add(
        AuditCheck(
          id: 'readme-sections',
          label: 'README con todas las secciones obligatorias',
          passed: sections.isEmpty,
          detail: sections.isEmpty ? null : 'Faltan: ${sections.join(", ")}',
          severity: 'required',
        ),
      );

      checks.add(
        AuditCheck(
          id: 'readme-multilang',
          label: 'README con bloque multi-idioma (ES, EN, PT)',
          passed: hasMultiLang,
          detail: hasMultiLang
              ? null
              : 'Debe incluir 🇪🇸 🇬🇧 🇧🇷 como mínimo',
          severity: 'recommended',
        ),
      );
    } catch (_) {
      checks.add(
        AuditCheck(
          id: 'readme-readable',
          label: 'README legible',
          passed: false,
          detail: 'No se pudo leer el archivo',
          severity: 'required',
        ),
      );
    }

    return checks;
  }

  // ─── Paso 3.6: Privacidad iOS ───

  List<AuditCheck> _checkIOSPrivacy(Set<String> names, Set<String> paths) {
    final checks = <AuditCheck>[];

    // Detectar si es iOS
    final hasIOS = paths.any(
      (p) => p.contains('/ios/') || p.contains('/macos/'),
    );

    if (!hasIOS) return checks;

    final hasInfoPlist = paths.any((p) => p.endsWith('Info.plist'));

    checks.add(
      AuditCheck(
        id: 'ios-infoplist',
        label: '[iOS] Info.plist presente',
        passed: hasInfoPlist,
        severity: 'required',
      ),
    );

    if (hasInfoPlist) {
      // Verificar SKAdNetworkItems (simplificado)
      bool hasSkAd = false;
      bool hasTracking = false;
      for (final p in paths) {
        if (p.endsWith('Info.plist')) {
          try {
            final content = File(p).readAsStringSync();
            hasSkAd = content.contains('SKAdNetworkItems');
            hasTracking = content.contains('NSUserTrackingUsageDescription');
          } catch (_) {}
        }
      }

      checks.add(
        AuditCheck(
          id: 'ios-skadnetwork',
          label: '[iOS] SKAdNetworkItems en Info.plist',
          passed: hasSkAd,
          detail: hasSkAd ? null : 'Required para atribución de anuncios',
          severity: 'required',
        ),
      );

      checks.add(
        AuditCheck(
          id: 'ios-tracking',
          label: '[iOS] NSUserTrackingUsageDescription',
          passed: hasTracking,
          severity: 'required',
        ),
      );
    }

    return checks;
  }

  // ─── Paso 3.7: Seguridad npm ───

  List<AuditCheck> _checkNpmSecurity(List<File> files, Set<String> paths) {
    final checks = <AuditCheck>[];

    final hasLockfile = paths.any(
      (p) =>
          p.endsWith('package-lock.json') ||
          p.endsWith('yarn.lock') ||
          p.endsWith('pnpm-lock.yaml'),
    );

    checks.add(
      AuditCheck(
        id: 'npm-lockfile',
        label: '[npm] Lockfile presente (package-lock.json o similar)',
        passed: hasLockfile,
        detail: hasLockfile ? null : 'Usa npm ci para builds deterministas',
        severity: 'recommended',
      ),
    );

    // Verificar scripts peligrosos
    bool hasDangerousScripts = false;
    for (final p in paths) {
      if (p.endsWith('package.json')) {
        try {
          final content = File(p).readAsStringSync();
          hasDangerousScripts =
              content.contains('"postinstall"') ||
              content.contains('"preinstall"');
        } catch (_) {}
      }
    }

    checks.add(
      AuditCheck(
        id: 'npm-no-dangerous-scripts',
        label: '[npm] Sin scripts peligrosos (postinstall, preinstall)',
        passed: !hasDangerousScripts,
        detail: hasDangerousScripts ? 'Revisar scripts de instalación' : null,
        severity: 'warning',
      ),
    );

    return checks;
  }

  // ─── Paso 3.8: Skills Flutter/Dart ───

  List<AuditCheck> _checkFlutterSkills(Set<String> names, Set<String> paths) {
    final checks = <AuditCheck>[];

    // Tests
    final hasTestDir = paths.any((p) => p.contains('/test/'));
    checks.add(
      AuditCheck(
        id: 'flutter-tests',
        label: '[Flutter] Carpeta test/ con tests',
        passed: hasTestDir,
        severity: 'recommended',
      ),
    );

    // Análisis estático
    final hasAnalysis = names.contains('analysis_options.yaml');
    checks.add(
      AuditCheck(
        id: 'flutter-lint',
        label: '[Flutter] Configuración de lint (analysis_options.yaml)',
        passed: hasAnalysis,
        severity: 'recommended',
      ),
    );

    // Estructura de carpetas
    final hasLib = paths.any((p) => p.contains('/lib/'));
    checks.add(
      AuditCheck(
        id: 'flutter-structure',
        label: '[Flutter] Estructura estándar (lib/, test/, etc.)',
        passed: hasLib,
        severity: 'required',
      ),
    );

    return checks;
  }

  // ─── Paso 3.9: Proyecto privado ───

  List<AuditCheck> _checkPrivateProject(List<File> files, Set<String> names) {
    final checks = <AuditCheck>[];

    // Detectar secretos
    bool hasEnvFile = names.contains('.env') || names.contains('.env.local');
    checks.add(
      AuditCheck(
        id: 'no-secrets-in-repo',
        label: '[Seguridad] Sin archivos .env en el repo',
        passed: !hasEnvFile,
        detail: hasEnvFile
            ? 'Potencial fuga de secretos. Revisar .gitignore'
            : null,
        severity: 'required',
      ),
    );

    // Detectar google-services.json o similar
    final hasServiceFiles =
        names.contains('google-services.json') ||
        names.contains('GoogleService-Info.plist');
    checks.add(
      AuditCheck(
        id: 'no-service-accounts',
        label: '[Seguridad] Sin service accounts en el repo',
        passed: !hasServiceFiles,
        detail: hasServiceFiles ? 'Posibles credenciales expuestas' : null,
        severity: 'required',
      ),
    );

    // .gitignore
    final hasGitignore = names.contains('.gitignore');
    checks.add(
      AuditCheck(
        id: 'gitignore-exists',
        label: '[Seguridad] .gitignore presente',
        passed: hasGitignore,
        severity: 'required',
      ),
    );

    return checks;
  }
}
