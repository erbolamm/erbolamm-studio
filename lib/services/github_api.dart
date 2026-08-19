import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/logging/app_logger.dart';

class GitHubApiService {
  static const String _baseUrl = 'https://api.github.com';

  Future<String?> _resolveToken() async {
    final envToken = Platform.environment['GITHUB_TOKEN'] ??
        Platform.environment['GH_TOKEN'];
    if (envToken != null && envToken.isNotEmpty) {
      return envToken;
    }
    try {
      final result = await Process.run('gh', ['auth', 'token']);
      if (result.exitCode == 0) {
        final token = (result.stdout as String).trim();
        if (token.isNotEmpty) return token;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'ErBolamm-Studio/1.0 (Flutter Desktop; macOS)',
    };
    final token = await _resolveToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>?> fetchRepoInfo(String owner, String repo) async {
    try {
      final headers = await _buildHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/repos/$owner/$repo'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      AppLogger.i('GitHub API returned ${response.statusCode} for $owner/$repo', 'GitHubApiService');
      return null;
    } catch (e, st) {
      AppLogger.e('Error fetching repo info', e, st, 'GitHubApiService');
      return null;
    }
  }

  /// Obtiene el texto plano del README sin decodificar Base64
  Future<String?> fetchRawReadme(String owner, String repo) async {
    try {
      final headers = await _buildHeaders();
      headers['Accept'] = 'application/vnd.github.raw+json';
      final response = await http.get(
        Uri.parse('$_baseUrl/repos/$owner/$repo/readme'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return response.body;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Obtiene el árbol completo de archivos en 1 sola llamada sin clonar el repositorio
  Future<List<String>?> fetchRepoTree(String owner, String repo) async {
    try {
      final headers = await _buildHeaders();
      // Probar rama por defecto vía HEAD
      final response = await http.get(
        Uri.parse('$_baseUrl/repos/$owner/$repo/git/trees/HEAD?recursive=1'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final tree = data['tree'] as List<dynamic>?;
        if (tree != null) {
          return tree
              .map((item) => (item as Map)['path'] as String?)
              .whereType<String>()
              .toList();
        }
      }
      return null;
    } catch (e, st) {
      AppLogger.e('Error fetching repo tree', e, st, 'GitHubApiService');
      return null;
    }
  }

  Future<bool> hasFile(String owner, String repo, String path) async {
    try {
      final headers = await _buildHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/repos/$owner/$repo/contents/$path'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>?> listContents(String owner, String repo, {String path = ''}) async {
    try {
      final headers = await _buildHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/repos/$owner/$repo/contents/$path'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
