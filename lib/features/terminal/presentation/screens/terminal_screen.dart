import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../services/project_monitor.dart';
import '../../domain/terminal_service.dart';

class TerminalScreen extends StatefulWidget {
  final ProjectMonitor? monitor;

  const TerminalScreen({super.key, this.monitor});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final _service = TerminalService();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  final List<_TerminalEntry> _history = [];
  String _cwd = '';
  Map<String, bool> _installedTools = {};

  @override
  void initState() {
    super.initState();
    final activePath = widget.monitor?.projectPath;
    if (activePath != null && activePath.isNotEmpty) {
      _service.setCwd(activePath);
    }
    _cwd = _service.cwd;
    _appendSystem('Terminal ErBolamm Studio — Contexto de Proyecto & Agentes IA');
    if (widget.monitor?.projectName != null) {
      _appendSystem('📁 Proyecto Activo: ${widget.monitor!.projectName}');
    }
    _appendSystem('Directorio: $_cwd');
    _appendSystem('');

    _detectTools();
  }

  Future<void> _detectTools() async {
    final tools = await _service.detectInstalledTools();
    if (mounted) {
      setState(() {
        _installedTools = tools;
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Terminal'),
            if (widget.monitor?.projectName != null) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.educacion.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '📂 ${widget.monitor!.projectName}',
                  style: const TextStyle(fontSize: 12, color: AppColors.educacion),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.medical_services_outlined),
            tooltip: 'Ejecutar Diagnóstico (Doctor)',
            onPressed: () => _runQuickCommand('dart run bin/studio.dart doctor'),
          ),
          IconButton(
            icon: const Icon(Icons.public_outlined),
            tooltip: 'Ver Proyectos en Universo',
            onPressed: () => _runQuickCommand('dart run bin/studio.dart list'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Limpiar',
            onPressed: _clear,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Guía de Comandos (CLI)',
            onPressed: _showTerminalGuideDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de Agentes y Herramientas Detectadas
          if (_installedTools.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: const Color(0xFF0e0e16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text(
                      'Entorno:',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ..._installedTools.entries.map((entry) {
                      final isInstalled = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isInstalled
                                ? AppColors.cultura.withValues(alpha: 0.15)
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isInstalled
                                  ? AppColors.cultura.withValues(alpha: 0.4)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isInstalled ? Icons.check_circle : Icons.circle_outlined,
                                size: 10,
                                color: isInstalled ? AppColors.cultura : AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isInstalled ? AppColors.textPrimary : AppColors.textMuted,
                                  fontWeight: isInstalled ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          // Barra de Botones Rápidos
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF151520),
              border: Border(bottom: BorderSide(color: Color(0xFF2A2A3A))),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickButton(
                    icon: Icons.check_circle_outline,
                    label: '🦋 Flutter Analyze',
                    color: AppColors.educacion,
                    onTap: () => _runQuickCommand('flutter analyze'),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickButton(
                    icon: Icons.play_arrow_rounded,
                    label: '🧪 Flutter Test',
                    color: AppColors.cultura,
                    onTap: () => _runQuickCommand('flutter test'),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickButton(
                    icon: Icons.smart_toy_outlined,
                    label: '🤖 Gentle Review',
                    color: AppColors.ia,
                    onTap: () => _runQuickCommand('gentle-ai review status'),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickButton(
                    icon: Icons.medical_services_rounded,
                    label: '🩺 Doctor',
                    color: AppColors.herramientas,
                    onTap: () => _runQuickCommand('dart run bin/studio.dart doctor'),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickButton(
                    icon: Icons.public_rounded,
                    label: '🌌 Universo',
                    color: AppColors.cultura,
                    onTap: () => _runQuickCommand('dart run bin/studio.dart list'),
                  ),
                ],
              ),
            ),
          ),
          // Output area
          Expanded(
            child: GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              child: Container(
                color: const Color(0xFF0a0a14),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _history.length + 1, // +1 for input line
                  itemBuilder: (context, index) {
                    if (index == _history.length) {
                      return _buildInputLine();
                    }
                    return _buildEntry(_history[index]);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntry(_TerminalEntry entry) {
    final isCommand = entry.type == _TerminalEntryType.command;

    if (entry.text == '__CLEAR__') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: SelectableText.rich(
        TextSpan(
          children: [
            if (isCommand) ...[
              const TextSpan(
                text: '❯ ',
                style: TextStyle(
                  color: AppColors.cultura,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            TextSpan(
              text: entry.text,
              style: TextStyle(
                color: isCommand
                    ? AppColors.textPrimary
                    : entry.type == _TerminalEntryType.error
                    ? AppColors.creacion
                    : entry.type == _TerminalEntryType.system
                    ? AppColors.textMuted
                    : AppColors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLine() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          '❯ ',
          style: TextStyle(
            color: AppColors.cultura,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            fontSize: 13,
          ),
        ),
        Expanded(
          child: TextField(
            controller: _inputController,
            focusNode: _focusNode,
            autofocus: true,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: 'mmx text chat "hola" ...',
              hintStyle: TextStyle(
                color: AppColors.textMuted,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
            cursorColor: AppColors.cultura,
            onSubmitted: (_) => _execute(),
          ),
        ),
      ],
    );
  }

  void _execute() {
    final input = _inputController.text;
    if (input.isEmpty) return;

    _inputController.clear();

    // Show command in history
    setState(() {
      _history.add(
        _TerminalEntry(
          '${_shortPath(_cwd)} $input',
          _TerminalEntryType.command,
        ),
      );
    });

    // Handle clear locally
    if (input.trim() == 'clear' || input.trim() == 'cls') {
      setState(() {
        _history.clear();
      });
      return;
    }

    // Run command
    _service.run(input).then((result) {
      if (!mounted) return;

      setState(() {
        _cwd = _service.cwd;

        if (result.stdout.isNotEmpty) {
          for (final line in result.stdout.split('\n')) {
            if (line.isNotEmpty) {
              _history.add(_TerminalEntry(line, _TerminalEntryType.output));
            }
          }
        }

        if (result.stderr.isNotEmpty) {
          for (final line in result.stderr.split('\n')) {
            if (line.isNotEmpty) {
              _history.add(_TerminalEntry(line, _TerminalEntryType.error));
            }
          }
        }
      });

      _scrollToBottom();
    });
  }

  void _clear() {
    setState(() {
      _history.clear();
      _appendSystem('Terminal limpiada.');
    });
  }

  void _appendSystem(String text) {
    _history.add(_TerminalEntry(text, _TerminalEntryType.system));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _runQuickCommand(String cmd) {
    _inputController.text = cmd;
    _execute();
  }

  Widget _buildQuickButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTerminalGuideDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151520),
        title: const Row(
          children: [
            Icon(Icons.terminal_rounded, color: AppColors.cultura),
            SizedBox(width: 10),
            Text('Guía de Comandos (CLI)', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Podés manejar ErBolamm Studio sin abrir la ventana gráfica usando estos comandos desde tu terminal:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                _buildGuideItem(
                  '🩺 Diagnóstico del Sistema',
                  'dart run bin/studio.dart doctor',
                  'Verifica si tenés Node.js, pnpm, ffmpeg, MiniMax CLI y tus claves de IA.',
                ),
                const SizedBox(height: 12),
                _buildGuideItem(
                  '🌌 Listar Proyectos del Universo',
                  'dart run bin/studio.dart list',
                  'Muestra todos los proyectos registrados en universe.json con sus pilares y landings.',
                ),
                const SizedBox(height: 12),
                _buildGuideItem(
                  '🔍 Analizar Repositorio o Carpeta',
                  'dart run bin/studio.dart analyze <url_o_ruta>',
                  'Ejemplo: dart run bin/studio.dart analyze https://github.com/erbolamm/apliarte-link',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido 👍'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(String title, String code, String desc) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            code,
            style: const TextStyle(
              color: AppColors.creacion,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _shortPath(String path) {
    final home = _service.cwd;
    if (path == home) return '~';
    if (path.startsWith(home)) return '~${path.substring(home.length)}';
    return path;
  }
}

enum _TerminalEntryType { command, output, error, system }

class _TerminalEntry {
  final String text;
  final _TerminalEntryType type;

  const _TerminalEntry(this.text, this.type);
}
