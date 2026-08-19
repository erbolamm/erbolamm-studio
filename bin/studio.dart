#!/usr/bin/env dart
// ignore_for_file: avoid_print
// ═══════════════════════════════════════════════════════════════
// 🚀 ErBolamm Studio CLI — Terminal Runner
// ═══════════════════════════════════════════════════════════════
// Permite operar la suite desde la línea de comandos sin abrir la GUI.
//
// Comandos:
//   dart run bin/studio.dart process <path>
//   dart run bin/studio.dart analyze <url_o_path>
//   dart run bin/studio.dart pipeline <path>
//   dart run bin/studio.dart promo <path>
//   dart run bin/studio.dart list
//   dart run bin/studio.dart doctor
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:erbolamm_studio/features/analyzer/domain/rules_engine.dart';
import 'package:erbolamm_studio/features/orchestrator/orchestration/pipeline_runner.dart';
import 'package:erbolamm_studio/features/orchestrator/agents/marketing_agent.dart';
import 'package:erbolamm_studio/features/orchestrator/services/promo_renderer.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    _printHelp();
    exit(0);
  }

  final command = args[0].toLowerCase();

  switch (command) {
    case 'process':
    case 'run':
      if (args.length < 2) {
        print('❌ Uso: dart run bin/studio.dart process <project_path>');
        exit(1);
      }
      await _runProcess(args[1]);
      break;

    case 'analyze':
      if (args.length < 2) {
        print('❌ Uso: dart run bin/studio.dart analyze <url_o_path>');
        exit(1);
      }
      await _runAnalyze(args[1]);
      break;

    case 'pipeline':
    case 'orchestrate':
      if (args.length < 2) {
        print('❌ Uso: dart run bin/studio.dart pipeline <project_path>');
        exit(1);
      }
      await _runPipeline(args[1]);
      break;

    case 'promo':
    case 'marketing':
      if (args.length < 2) {
        print('❌ Uso: dart run bin/studio.dart promo <project_path>');
        exit(1);
      }
      await _runMarketing(args[1]);
      break;

    case 'list':
      await _runList();
      break;

    case 'doctor':
      await _runDoctor();
      break;

    case '--help':
    case '-h':
    case 'help':
      _printHelp();
      break;

    default:
      print('❌ Comando desconocido: "$command"');
      _printHelp();
      exit(1);
  }
}

void _printHelp() {
  print('''
\x1B[1m\x1B[36m╔═══════════════════════════════════════════════════╗
║          🧠 ErBolamm Studio CLI Runner            ║
╚═══════════════════════════════════════════════════╝\x1B[0m

\x1B[1mCOMANDOS DISPONIBLES:\x1B[0m
  \x1B[32mprocess <path>\x1B[0m          Procesa un proyecto de punta a punta (análisis + specs + capturas + media)
  \x1B[32manalyze <url_o_path>\x1B[0m    Analiza un repositorio remoto o local según INBOX.md
  \x1B[32mpipeline <path>\x1B[0m         Ejecuta el pipeline completo de agentes autónomos
  \x1B[32mpromo <path>\x1B[0m            Genera assets de marketing (screenshots Flutter, audio, mmx, video)
  \x1B[32mlist\x1B[0m                   Muestra todos los proyectos registrados en universe.json
  \x1B[32mdoctor\x1B[0m                 Verifica herramientas instaladas y estado de IA
  \x1B[32mhelp\x1B[0m                   Muestra esta ayuda

\x1B[1mEJEMPLOS:\x1B[0m
  dart run bin/studio.dart process /Users/apliarte/trabajo/lenguaje_no_verbal
  dart run bin/studio.dart analyze /Users/apliarte/trabajo/afinar_de_oido
  dart run bin/studio.dart doctor
''');
}

Future<void> _runProcess(String projectPath) async {
  final dir = Directory(projectPath);
  if (!dir.existsSync()) {
    print('\x1B[31m❌ La ruta del proyecto no existe: "$projectPath"\x1B[0m');
    exit(1);
  }

  final projectName = p.basename(projectPath);
  print('\n\x1B[1m\x1B[36m🚀 Procesando proyecto "$projectName" en modo directo...\x1B[0m');
  print('  📁 Ruta: \x1B[90m$projectPath\x1B[0m\n');

  // 1. Análisis
  print('\x1B[1m[1/3] 🔍 Analizando repositorio y verificando estándares...\x1B[0m');
  final engine = RulesEngine();
  final analysis = await engine.analyzeRepo(projectPath);
  print('  • Nombre:       ${analysis.name}');
  print('  • Tipo:         ${analysis.projectType.name}');
  print('  • Descripción:  ${analysis.description ?? "N/A"}');

  // 2. Marketing Agent + Generación de specs y capturas de tiendas
  print('\n\x1B[1m[2/3] 🎨 Generando Brand Spec, narraciones y capturas enmarcadas...\x1B[0m');
  final agent = MarketingAgent();
  final output = await agent.execute(projectPath);

  if (output.success) {
    print('  ✅ \x1B[32m${output.summary}\x1B[0m');
    for (final f in output.artifacts) {
      print('    • \x1B[90m$f\x1B[0m');
    }
  } else {
    print('  ⚠️ \x1B[33m${output.summary}: ${output.error}\x1B[0m');
  }

  // 3. Render multimedia
  print('\n\x1B[1m[3/3] 🎬 Verificando renderizado de audio y video...\x1B[0m');
  final videoResult = await PromoRenderer.renderSlideshow(projectPath: projectPath);
  if (videoResult.success) {
    print('  ✅ Video promocional renderizado: \x1B[32m${videoResult.filePath}\x1B[0m');
  } else {
    print('  ℹ️  ${videoResult.error ?? 'Renderizado de video omitido o pendiente'}');
  }

  print('\n\x1B[1m\x1B[32m🎉 ¡Procesamiento completado con éxito!\x1B[0m');
  print('  📦 Todos los artefactos fueron guardados en: \x1B[1m\x1B[36m$projectPath/erbolamm-studio/\x1B[0m\n');
}

Future<void> _runAnalyze(String target) async {
  print('\x1B[34m🔍 Analizando "$target"...\x1B[0m');
  final engine = RulesEngine();

  try {
    final result = await engine.analyzeRepo(target);
    print('\n\x1B[1m\x1B[32m✅ Resultado del Análisis:\x1B[0m');
    print('  • Nombre:       ${result.name}');
    print('  • Propietario:  ${result.owner}');
    print('  • Tipo:         ${result.projectType.name}');
    if (result.description != null) {
      print('  • Descripción:  ${result.description}');
    }

    print('\n\x1B[1m📋 Verificación de Plantilla:\x1B[0m');
    _printCheck('README.md', result.hasReadme);
    _printCheck('LICENSE', result.hasLicense);
    _printCheck('Carpeta promo/', result.hasPromoFolder);
    _printCheck('Screenshots', result.hasScreenshots);
    _printCheck('Video promo', result.hasVideo);
    _printCheck('Landing page', result.hasLanding, extra: result.landingUrl);

    if (result.missingItems.isNotEmpty) {
      print('\n\x1B[33m⚠️  Items pendientes (${result.missingItems.length}):\x1B[0m');
      for (final item in result.missingItems) {
        print('  - $item');
      }
    } else {
      print('\n\x1B[32m🎉 ¡El proyecto cumple 100% con la plantilla ErBolamm!\x1B[0m');
    }
  } catch (e) {
    print('\x1B[31m❌ Error durante el análisis: $e\x1B[0m');
    exit(1);
  }
}

void _printCheck(String label, bool ok, {String? extra}) {
  final icon = ok ? '\x1B[32m[OK]\x1B[0m' : '\x1B[31m[FALTA]\x1B[0m';
  final extraText = extra != null ? ' \x1B[90m($extra)\x1B[0m' : '';
  print('  $icon $label$extraText');
}

Future<void> _runPipeline(String projectPath) async {
  print('\n\x1B[1m\x1B[36m🚀 Ejecutando Pipeline de Agentes para "$projectPath"...\x1B[0m\n');
  final runner = PipelineRunner(projectPath: projectPath);

  runner.setCallbacks(
    onStart: (agentId) => print('  ▶️  Iniciando agente: \x1B[33m$agentId\x1B[0m...'),
    onDone: (agentId, success, summary, error) {
      final icon = success ? '\x1B[32m✅\x1B[0m' : '\x1B[31m❌\x1B[0m';
      print('  $icon Agente \x1B[1m$agentId\x1B[0m: $summary');
      if (error != null) print('     \x1B[31mError: $error\x1B[0m');
    },
  );

  final result = await runner.runAll();
  print('\n\x1B[1m🏁 Pipeline finalizado en ${result.totalDuration.inSeconds}s (Éxito: ${result.allSucceeded})\x1B[0m\n');
}

Future<void> _runMarketing(String projectPath) async {
  print('\n\x1B[1m\x1B[35m🎨 Ejecutando MarketingAgent para "$projectPath"...\x1B[0m\n');
  final agent = MarketingAgent();
  final output = await agent.execute(projectPath);

  if (output.success) {
    print('  ✅ \x1B[32m${output.summary}\x1B[0m');
    for (final f in output.artifacts) {
      print('    • Generado: \x1B[90m$f\x1B[0m');
    }
  } else {
    print('  ❌ \x1B[31m${output.summary}: ${output.error}\x1B[0m');
  }

  // Intentar renderizado de audio y video si ffmpeg está presente
  print('\n\x1B[34m🎬 Verificando renderizado multimedia (PromoRenderer)...\x1B[0m');
  final videoResult = await PromoRenderer.renderSlideshow(projectPath: projectPath);
  if (videoResult.success) {
    print('  ✅ Video promocional renderizado: \x1B[32m${videoResult.filePath}\x1B[0m');
  } else {
    print('  ℹ️  ${videoResult.error ?? 'Renderizado de video omitido o pendiente'}');
  }
}

Future<void> _runList() async {
  final file = File('universe.json');
  if (!file.existsSync()) {
    print('⚠️ universe.json no encontrado en el directorio actual.');
    return;
  }

  try {
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final projects = data['projects'] as List<dynamic>? ?? [];

    print('\n\x1B[1m\x1B[36m🌌 Proyectos en el Universo ErBolamm (${projects.length}):\x1B[0m\n');
    for (final p in projects) {
      if (p is Map) {
        final name = p['name'] ?? p['id'];
        final pillar = p['pillar'] ?? 'sin pilar';
        final type = p['type'] ?? 'general';
        final urls = p['urls'] as Map? ?? {};
        final landing = urls['landing'] ?? urls['web'] ?? 'sin web';

        print('  \x1B[1m• $name\x1B[0m [\x1B[35m$pillar\x1B[0m / \x1B[34m$type\x1B[0m]');
        print('    Landing: \x1B[90m$landing\x1B[0m');
      }
    }
    print('');
  } catch (e) {
    print('❌ Error al leer universe.json: $e');
  }
}

Future<void> _runDoctor() async {
  print('\n\x1B[1m\x1B[36m🩺 ErBolamm Studio Doctor:\x1B[0m\n');

  await _checkTool('Node.js', 'node', ['--version']);
  await _checkTool('pnpm', 'pnpm', ['--version']);
  await _checkTool('ffmpeg', 'ffmpeg', ['-version']);
  await _checkTool('MiniMax CLI (mmx)', 'mmx', ['--version']);
  await _checkTool('GitHub CLI (gh)', 'gh', ['--version']);

  print('\n\x1B[1m🤖 Variables de Entorno de Proveedores IA:\x1B[0m');
  final env = Platform.environment;
  _checkEnv('DEEPSEEK_API_KEY', '🐋 DeepSeek', env);
  _checkEnv('MINIMAX_API_KEY', '⚡ MiniMax', env);
  _checkEnv('ANTHROPIC_API_KEY', '🤖 Claude', env);
  _checkEnv('OPENAI_API_KEY', '🧠 OpenAI', env);
  _checkEnv('GEMINI_API_KEY', '✨ Gemini', env);
  _checkEnv('GROQ_API_KEY', '⚡ Groq', env);
  _checkEnv('NVIDIA_API_KEY', '🟢 NVIDIA NIM', env);
  print('');
}

void _checkEnv(String varName, String label, Map<String, String> env) {
  final hasKey = env[varName] != null && env[varName]!.isNotEmpty;
  final status = hasKey ? '\x1B[32mConfigurado ($varName) ✅\x1B[0m' : '\x1B[90mNo detectado ⚪\x1B[0m';
  print('  • ${label.padRight(18)}: $status');
}

Future<void> _checkTool(String name, String executable, List<String> args) async {
  try {
    final res = await Process.run(executable, args);
    if (res.exitCode == 0) {
      final firstLine = (res.stdout as String).split('\n').first.trim();
      print('  ✅ $name: \x1B[32m$firstLine\x1B[0m');
    } else {
      print('  ⚠️  $name: código de salida ${res.exitCode}');
    }
  } catch (_) {
    print('  ❌ $name: \x1B[31mNo instalado o no en PATH\x1B[0m');
  }
}
