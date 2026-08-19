import 'dart:async';
import 'dart:io';

/// Entry de salida de la terminal (una línea).
class TerminalLine {
  final String text;
  final TerminalLineType type;

  const TerminalLine(this.text, this.type);

  factory TerminalLine.output(String text) =>
      TerminalLine(text, TerminalLineType.output);

  factory TerminalLine.error(String text) =>
      TerminalLine(text, TerminalLineType.error);

  factory TerminalLine.command(String text) =>
      TerminalLine(text, TerminalLineType.command);

  factory TerminalLine.system(String text) =>
      TerminalLine(text, TerminalLineType.system);
}

enum TerminalLineType { output, error, command, system }

/// Resultado de un comando ejecutado.
class CommandResult {
  final String stdout;
  final String stderr;
  final int exitCode;

  const CommandResult({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
  });

  bool get isSuccess => exitCode == 0;
}

/// Servicio de terminal: ejecuta comandos del sistema via Process.run.
class TerminalService {
  String _cwd;

  TerminalService({String? initialCwd})
      : _cwd = initialCwd ?? _defaultCwd();

  static String _defaultCwd() {
    return Directory.current.path;
  }

  String get cwd => _cwd;

  /// Cambia el directorio de trabajo
  void setCwd(String newPath) {
    if (Directory(newPath).existsSync()) {
      _cwd = newPath;
    }
  }

  /// Detecta herramientas CLI y Coding Agents instalados en el host
  Future<Map<String, bool>> detectInstalledTools() async {
    final tools = [
      'gentle-ai',
      'opencode',
      'claude',
      'codex',
      'pi',
      'flutter',
      'dart',
      'gh',
    ];
    final result = <String, bool>{};
    for (final tool in tools) {
      try {
        final res = await Process.run('which', [tool]);
        result[tool] =
            res.exitCode == 0 && (res.stdout as String).trim().isNotEmpty;
      } catch (_) {
        result[tool] = false;
      }
    }
    return result;
  }

  /// Ejecuta un comando de shell (separado por pipes).
  /// Retorna CommandResult con stdout/stderr.
  Future<CommandResult> run(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const CommandResult(stdout: '', stderr: '', exitCode: 0);
    }

    // Built-in: cd
    if (trimmed.startsWith('cd ')) {
      return _handleCd(trimmed.substring(3).trim());
    }

    // Built-in: clear
    if (trimmed == 'clear' || trimmed == 'cls') {
      return const CommandResult(stdout: '__CLEAR__', stderr: '', exitCode: 0);
    }

    // Built-in: pwd
    if (trimmed == 'pwd') {
      return CommandResult(stdout: _cwd, stderr: '', exitCode: 0);
    }

    // Built-in: exit / quit
    if (trimmed == 'exit' || trimmed == 'quit') {
      return const CommandResult(stdout: '', stderr: '', exitCode: 0);
    }

    // Built-in: help
    if (trimmed == 'help' || trimmed == '?') {
      return CommandResult(
        stdout: _helpText(),
        stderr: '',
        exitCode: 0,
      );
    }

    // Built-in: history
    if (trimmed == 'history') {
      return const CommandResult(
        stdout: '(historial en desarrollo)',
        stderr: '',
        exitCode: 0,
      );
    }

    // Ejecutar comando externo con Process.run
    return _runExternal(trimmed);
  }

  CommandResult _handleCd(String path) {
    String target;

    if (path.isEmpty || path == '~') {
      target = Platform.environment['HOME'] ?? '/tmp';
    } else if (path == '..') {
      final parent = Directory(_cwd).parent;
      target = parent.path;
    } else if (path == '.') {
      return CommandResult(stdout: _cwd, stderr: '', exitCode: 0);
    } else if (path.startsWith('/')) {
      target = path;
    } else {
      target = '$_cwd/$path';
    }

    // Normalizar ..
    final dir = Directory(target);
    if (!dir.existsSync()) {
      return CommandResult(
        stdout: '',
        stderr: 'cd: no existe el directorio: $path',
        exitCode: 1,
      );
    }

    _cwd = dir.resolveSymbolicLinksSync();
    return CommandResult(stdout: '', stderr: '', exitCode: 0);
  }

  Future<CommandResult> _runExternal(String command) async {
    try {
      // Parsear pipes
      final parts = command.split(RegExp(r'\s*\|\s*'));
      String currentStdin = '';
      String lastStdout = '';
      int lastExitCode = 0;

      for (int i = 0; i < parts.length; i++) {
        final part = parts[i].trim();
        if (part.isEmpty) continue;

        final parsed = _parseCommand(part);
        if (parsed == null) {
          return CommandResult(
            stdout: lastStdout,
            stderr: 'syntax error: comando inválido',
            exitCode: 1,
          );
        }

        final result = await Process.run(
          parsed.executable,
          parsed.args,
          workingDirectory: _cwd,
          environment: Platform.environment,
          runInShell: true,
        );

        currentStdin = result.stdout as String;
        lastStdout = currentStdin;
        lastExitCode = result.exitCode;

        if (result.exitCode != 0 && i < parts.length - 1) {
          // Pipe con error en medio — continuar pero marcar
        }
      }

      return CommandResult(
        stdout: lastStdout,
        stderr: '',
        exitCode: lastExitCode,
      );
    } catch (e) {
      return CommandResult(
        stdout: '',
        stderr: 'error: $e',
        exitCode: 1,
      );
    }
  }

  /// Parsea "comando arg1 arg2 ..." extrayendo el ejecutable y argumentos.
  /// Maneja expansión básica de ~.
  _ParsedCommand? _parseCommand(String raw) {
    final tokens = _tokenize(raw);
    if (tokens.isEmpty) return null;

    final executable = tokens[0];
    final args = tokens.sublist(1).map((a) {
      if (a.startsWith('~') && (a == '~' || a.startsWith('~/'))) {
        return a.replaceFirst('~', Platform.environment['HOME'] ?? '/tmp');
      }
      return a;
    }).toList();

    return _ParsedCommand(executable, args);
  }

  List<String> _tokenize(String input) {
    final tokens = <String>[];
    final buf = StringBuffer();
    bool inQuote = false;
    String? quoteChar;

    for (int i = 0; i < input.length; i++) {
      final c = input[i];
      if (inQuote) {
        if (c == quoteChar) {
          inQuote = false;
          quoteChar = null;
        } else {
          buf.write(c);
        }
      } else if (c == '"' || c == "'") {
        inQuote = true;
        quoteChar = c;
      } else if (c == ' ' || c == '\t') {
        if (buf.isNotEmpty) {
          tokens.add(buf.toString());
          buf.clear();
        }
      } else {
        buf.write(c);
      }
    }

    if (buf.isNotEmpty) {
      tokens.add(buf.toString());
    }

    return tokens;
  }

  String _helpText() => '''
Comandos disponibles:
  cd <dir>       Cambiar directorio
  pwd            Mostrar directorio actual
  ls [opts] [path]    Listar archivos
  cat <file>     Mostrar contenido de archivo
  echo <text>    Imprimir texto
  mkdir <dir>    Crear directorio
  rm <file>      Eliminar archivo
  rmdir <dir>    Eliminar directorio
  touch <file>   Crear archivo vacío
  cp <src> <dst> Copiar archivo
  mv <src> <dst> Mover/renombrar archivo
  find <path> <name>  Buscar archivos
  grep <pat> <file>   Buscar en archivo
  clear          Limpiar pantalla
  help           Mostrar esta ayuda
  <comando>      Ejecutar cualquier comando del sistema

Usa | para pipe: ls | head
''';
}

class _ParsedCommand {
  final String executable;
  final List<String> args;

  _ParsedCommand(this.executable, this.args);
}
