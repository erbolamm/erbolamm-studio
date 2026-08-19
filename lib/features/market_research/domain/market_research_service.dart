import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../../../core/logging/app_logger.dart';

// ═══════════════════════════════════════════════════════════════
// 📊 MarketResearchService — Tendencias Reales y Newsjacking
// ═══════════════════════════════════════════════════════════════
// Conecta con feeds de noticias en vivo (Google News RSS España/Tech)
// y genera ganchos promocionales cruzados (Newsjacking) con IA
// conectando la actualidad del día con el proyecto analizado.
// ═══════════════════════════════════════════════════════════════

/// Una tendencia obtenida de búsqueda real en vivo.
class Trend {
  final String title;
  final String source;
  final String category;
  final double relevance;
  final String angle;

  const Trend({
    required this.title,
    required this.source,
    required this.category,
    required this.relevance,
    required this.angle,
  });

  factory Trend.fromJson(Map<String, dynamic> json) {
    return Trend(
      title: json['title'] as String? ?? '',
      source: json['source'] as String? ?? 'Web',
      category: json['category'] as String? ?? 'General',
      relevance: (json['relevance'] as num?)?.toDouble() ?? 0.85,
      angle: json['angle'] as String? ?? '',
    );
  }
}

/// Un hook promocional generado por IA para Newsjacking.
class PromoHook {
  final String hook;
  final String platform;
  final String tone;

  const PromoHook({
    required this.hook,
    required this.platform,
    required this.tone,
  });
}

class MarketResearchService {
  /// Feeds RSS de noticias reales en vivo
  static const _rssFeeds = [
    (
      url: 'https://news.google.com/rss/headlines/section/topic/TECHNOLOGY?hl=es-ES&gl=ES&ceid=ES:es',
      category: 'Tecnología e IA',
    ),
    (
      url: 'https://news.google.com/rss?hl=es-ES&gl=ES&ceid=ES:es',
      category: 'Actualidad Nacional',
    ),
    (
      url: 'https://news.google.com/rss/headlines/section/topic/BUSINESS?hl=es-ES&gl=ES&ceid=ES:es',
      category: 'Startups y Negocios',
    ),
  ];

  /// Busca tendencias reales en vivo (RSS + Web en tiempo real).
  static Future<List<Trend>> fetchTrends() async {
    final trends = <Trend>[];

    // 1. Obtener noticias frescas en vivo de Google News RSS
    for (final feed in _rssFeeds) {
      try {
        final response = await http
            .get(Uri.parse(feed.url))
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final items = _parseRssItems(response.body, feed.category);
          trends.addAll(items.take(3));
        }
      } catch (e) {
        AppLogger.i('[MarketResearch] Error leyendo RSS (${feed.category}): $e');
      }
    }

    // 2. Si se obtuvieron tendencias reales, devolverlas ordenadas por relevancia
    if (trends.isNotEmpty) {
      AppLogger.i('[MarketResearch] ✅ ${trends.length} noticias y tendencias vivas obtenidas.');
      return trends.take(10).toList();
    }

    // 3. Fallback inteligente si no hay conexión a internet
    return _offlineTrends();
  }

  /// Parsea elementos `<item>` de un feed RSS
  static List<Trend> _parseRssItems(String xml, String defaultCategory) {
    final results = <Trend>[];
    final itemRegex = RegExp(r'<item>([\s\S]*?)<\/item>');
    final titleRegex = RegExp(r'<title>([\s\S]*?)<\/title>');
    final sourceRegex = RegExp(r'<source[^>]*>([\s\S]*?)<\/source>');

    for (final match in itemRegex.allMatches(xml)) {
      final itemXml = match.group(1) ?? '';
      final titleMatch = titleRegex.firstMatch(itemXml);
      if (titleMatch == null) continue;

      var rawTitle = titleMatch.group(1) ?? '';
      // Limpiar CDATA y entidades HTML
      rawTitle = rawTitle
          .replaceAll('<![CDATA[', '')
          .replaceAll(']]>', '')
          .replaceAll('&quot;', '"')
          .replaceAll('&apos;', "'")
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .trim();

      String source = 'Noticias Hoy';
      final sourceMatch = sourceRegex.firstMatch(itemXml);
      if (sourceMatch != null) {
        source = sourceMatch.group(1) ?? source;
      } else if (rawTitle.contains(' - ')) {
        final parts = rawTitle.split(' - ');
        source = parts.last.trim();
        rawTitle = parts.sublist(0, parts.length - 1).join(' - ').trim();
      }

      if (rawTitle.isNotEmpty) {
        results.add(
          Trend(
            title: rawTitle,
            source: source,
            category: defaultCategory,
            relevance: 0.90 + (results.length * 0.02).clamp(0.0, 0.08),
            angle: 'Breaking News • Tendencia del día',
          ),
        );
      }
    }

    return results;
  }

  /// Genera hooks promocionales con Newsjacking cruzando las tendencias de hoy con el proyecto.
  static Future<List<PromoHook>> generateHooks({
    required String projectName,
    required String projectPath,
    required List<Trend> trends,
  }) async {
    final context = _readProjectContext(projectPath, projectName);
    final topTrends = trends.take(4).toList();

    // Intentar generar hooks con IA (mmx o fallback dinámico contextual)
    try {
      final trendTexts = topTrends
          .map((t) => '• [${t.category}] ${t.title} (Fuente: ${t.source})')
          .join('\n');

      final prompt = '''Sos un estratega de marketing viral, Growth Hacker y maestro del "Newsjacking".
Tu misión es generar 4 hooks promocionales para publicar en redes sociales (X/Twitter, LinkedIn, TikTok/Reels, Facebook)
conectando ingeniosamente las NOTICIAS Y TENDENCIAS REALES DE HOY con este proyecto:

Proyecto: $projectName
Contexto:
$context

Tendencias y Noticias de Hoy:
$trendTexts

Instrucciones:
1. Usá el recurso del Newsjacking: vinculá la noticia del día con la solución o la potencia que ofrece el proyecto (o la fábrica de agentes de IA de apliarte).
2. Un hook debe tener tono de HUMOR/IRONÍA (ideal para X/Twitter).
3. Un hook debe tener tono PROFESIONAL/DISRUPTIVO (ideal para LinkedIn).
4. Un hook debe tener tono VIRAL/PROVOCADOR (ideal para TikTok / Reels).
5. Un hook debe tener tono COMUNITARIO/CURIOSIDAD (ideal para Facebook / Threads).
6. Cada hook debe empezar con un emoji y tener entre 2 y 4 líneas concisas y directas.

Respondé ÚNICAMENTE un array JSON válido con esta estructura:
[
  {"hook": "texto...", "platform": "X / Twitter", "tone": "humor"},
  {"hook": "texto...", "platform": "LinkedIn", "tone": "profesional"},
  {"hook": "texto...", "platform": "TikTok / Reels", "tone": "viral"},
  {"hook": "texto...", "platform": "Facebook", "tone": "comunitario"}
]''';

      final result = await Process.run('mmx', [
        'text',
        'chat',
        prompt,
        '--output',
        'json',
      ], runInShell: true).timeout(const Duration(seconds: 25));

      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final parsed = _extractJson(output);
        if (parsed is List) {
          final hooks = parsed
              .map(
                (h) => PromoHook(
                  hook: (h['hook'] ?? '').toString(),
                  platform: (h['platform'] ?? 'X / Twitter').toString(),
                  tone: (h['tone'] ?? 'viral').toString(),
                ),
              )
              .toList();
          if (hooks.isNotEmpty) return hooks;
        }
      }
    } catch (e) {
      AppLogger.i('[MarketResearch] Generación LLM CLI omitida, usando newsjacking contextual: $e');
    }

    // Generador dinámico de Newsjacking con noticias reales de hoy
    return _buildDynamicNewsjackingHooks(projectName, context, topTrends);
  }

  /// Construye ganchos de newsjacking inteligentes a partir de las noticias reales capturadas
  static List<PromoHook> _buildDynamicNewsjackingHooks(
    String projectName,
    String context,
    List<Trend> trends,
  ) {
    final t1 = trends.isNotEmpty ? trends[0].title : 'Las noticias de hoy en tecnología';
    final t2 = trends.length > 1 ? trends[1].title : 'El auge de la inteligencia artificial';
    final t3 = trends.length > 2 ? trends[2].title : 'Novedades de la industria tech';

    return [
      PromoHook(
        hook: '🔥 Mientras todos hablan de: "$t1"...\n\n'
            '¿Sabías que con $projectName resolvés exactamente lo que necesitás sin dar vueltas?\n'
            'Seguro hasta en las noticias usarían la fábrica de agentes de apliarte. 😉🚀',
        platform: 'X / Twitter',
        tone: 'humor / actualidad',
      ),
      PromoHook(
        hook: '📈 La tendencia de hoy es clara: "$t2".\n\n'
            'Las herramientas que marcan la diferencia en 2026 no son las más complejas, sino las que ejecutan con precisión quirúrgica como $projectName.\n'
            'La automatización real ya está acá. ¿Tu equipo ya lo implementó?',
        platform: 'LinkedIn',
        tone: 'profesional / liderazgo',
      ),
      PromoHook(
        hook: '👀 Pov: Estás leyendo "$t3" y te das cuenta de que con $projectName lo hacés en 3 clics.\n\n'
            'Menos humo, más código funcionando. Link en bio para probarlo gratis. ⚡💻',
        platform: 'TikTok / Reels',
        tone: 'viral / dinámico',
      ),
      PromoHook(
        hook: '💡 Debate del día: con todo lo que está pasando con "$t1", ¿hacia dónde va nuestro sector?\n\n'
            'Creamos $projectName justamente para simplificar esto. Dejame en comentarios qué te parece y cómo lo resolverías vos. 👇',
        platform: 'Facebook / Threads',
        tone: 'comunitario / debate',
      ),
    ];
  }

  static dynamic _extractJson(String text) {
    final match = RegExp(r'\[[\s\S]*\]').firstMatch(text);
    if (match != null) {
      return jsonDecode(match.group(0)!);
    }
    return jsonDecode(text);
  }

  static String _readProjectContext(String projectPath, String projectName) {
    final buffer = StringBuffer();

    for (final name in ['README.md', 'readme.md', 'Readme.md']) {
      final f = File('$projectPath/$name');
      if (f.existsSync()) {
        try {
          final lines = f.readAsLinesSync().take(15).join('\n');
          buffer.writeln('README: $lines');
          break;
        } catch (_) {}
      }
    }

    final pubspec = File('$projectPath/pubspec.yaml');
    if (pubspec.existsSync()) {
      try {
        for (final line in pubspec.readAsLinesSync()) {
          if (line.trimLeft().startsWith('description:')) {
            buffer.writeln(
              'Descripción: ${line.replaceAll(RegExp(r"description:\s*"), "").trim()}',
            );
          }
        }
      } catch (_) {}
    }

    if (buffer.isEmpty) {
      buffer.writeln('Proyecto: $projectName');
    }

    return buffer.toString();
  }

  static List<Trend> _offlineTrends() {
    return [
      Trend(
        title: 'IA Autónoma y Agentes de Software transforman el desarrollo en 2026',
        source: 'Tech Trends',
        category: 'Tecnología e IA',
        relevance: 0.95,
        angle: 'Automatización y agentes autónomos',
      ),
      Trend(
        title: 'El ecosistema de creadores de software acelera el time-to-market',
        source: 'Startup Ecosystem',
        category: 'Startups y Negocios',
        relevance: 0.90,
        angle: 'Productividad y lanzamiento ágil',
      ),
    ];
  }
}
