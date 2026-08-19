import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../models/repo_analysis.dart';

class ChecklistWidget extends StatelessWidget {
  final RepoAnalysis analysis;
  final VoidCallback? onSendToOrchestrator;
  final VoidCallback? onSaveToRegistry;
  final VoidCallback? onPublishToUniverse;
  final String? inbxProjectName;
  final VoidCallback? onAnalyzeInbox;

  const ChecklistWidget({
    super.key,
    required this.analysis,
    this.onSendToOrchestrator,
    this.onSaveToRegistry,
    this.onPublishToUniverse,
    this.inbxProjectName,
    this.onAnalyzeInbox,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info del repo
          _buildRepoCard(),
          const SizedBox(height: 20),

          // Score
          _buildScoreCard(),
          const SizedBox(height: 20),

          // Checks
          const Text(
            'Verificación de archivos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildCheckItem(
            'README.md',
            analysis.hasReadme,
            'Documentación principal del proyecto',
          ),
          _buildCheckItem(
            'LICENSE',
            analysis.hasLicense,
            'Licencia del proyecto',
          ),
          _buildCheckItem(
            'Carpeta promo/',
            analysis.hasPromoFolder,
            'Assets de marketing (screenshots, videos)',
          ),
          if (analysis.hasPromoFolder) ...[
            _buildCheckItem(
              'Screenshots',
              analysis.hasScreenshots,
              'Capturas de pantalla del proyecto',
              isSubItem: true,
            ),
            _buildCheckItem(
              'Videos',
              analysis.hasVideo,
              'Videos promocionales',
              isSubItem: true,
            ),
            _buildCheckItem(
              'brand-spec.md',
              analysis.hasBrandSpec,
              'Especificación de marca (colores, tipografía)',
              isSubItem: true,
            ),
          ],
          _buildCheckItem(
            'Landing page',
            analysis.hasLanding,
            'Página web de presentación',
          ),

          // Items faltantes
          if (analysis.missingItems.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildMissingItemsCard(),
          ],

          // Todo OK
          if (analysis.missingItems.isEmpty) _buildSuccessCard(),

          // Acciones
          const SizedBox(height: 24),
          _buildActionsCard(context),
        ],
      ),
    );
  }

  Widget _buildRepoCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.glassGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.educacion.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.folder_outlined,
                    size: 32,
                    color: AppColors.educacion,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${analysis.owner}/${analysis.name}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (analysis.description != null)
                        Text(
                          analysis.description!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.educacion.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.educacion.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${analysis.projectType.icon} ${analysis.projectType.label}',
                    style: const TextStyle(
                      color: AppColors.educacion,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (analysis.language != null)
                  _buildPillarChip(analysis.language!, AppColors.herramientas),
                ...analysis.topics
                    .take(5)
                    .map((topic) => _buildPillarChip(topic, AppColors.ia)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    final total = 7;
    final passed = [
      analysis.hasReadme,
      analysis.hasLicense,
      analysis.hasPromoFolder,
      analysis.hasScreenshots,
      analysis.hasVideo,
      analysis.hasLanding,
      analysis.hasBrandSpec,
    ].where((c) => c).length;

    final percentage = (passed / total * 100).round();
    final color = percentage >= 80
        ? AppColors.cultura
        : percentage >= 50
        ? AppColors.herramientas
        : AppColors.creacion;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), AppColors.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Puntuación',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$passed',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '/$total',
                  style: const TextStyle(
                    fontSize: 28,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: passed / total,
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$percentage% completado',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(
    String title,
    bool isComplete,
    String description, {
    bool isSubItem = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isComplete
            ? AppColors.cultura.withValues(alpha: 0.08)
            : AppColors.creacion.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete
              ? AppColors.cultura.withValues(alpha: 0.2)
              : AppColors.creacion.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isComplete
                ? AppColors.cultura.withValues(alpha: 0.2)
                : AppColors.creacion.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isComplete ? Icons.check_circle : Icons.cancel,
            color: isComplete ? AppColors.cultura : AppColors.creacion,
            size: isSubItem ? 20 : 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSubItem ? FontWeight.normal : FontWeight.bold,
            fontSize: isSubItem ? 14 : 16,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isComplete ? AppColors.cultura : AppColors.creacion,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isComplete ? 'OK' : 'FALTA',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMissingItemsCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.herramientas.withValues(alpha: 0.15),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.herramientas.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.herramientas,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Items pendientes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.herramientas,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...analysis.missingItems.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.herramientas,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.cultura.withValues(alpha: 0.2), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cultura.withValues(alpha: 0.4)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.cultura, size: 36),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Todo en orden!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cultura,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'El repo cumple con todos los requisitos de INBOX.md',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.alt_route_rounded, color: AppColors.ia, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Paso 2 de INBOX.md — ¿Qué hacemos con este proyecto?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Elegí una opción según el estado y objetivo del proyecto:',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),

          // Opción 1: Publicar / Enviar a Orchestrator
          _buildDecisionTile(
            context,
            icon: Icons.auto_awesome,
            color: AppColors.ia,
            title: '1. Procesar con Orchestrator (Recomendado)',
            description:
                'Ejecuta el pipeline autónomo: genera o audita carpeta promo/, screenshots, video promocional, locución multilingüe y landing page.',
            onTap: onSendToOrchestrator,
          ),
          const SizedBox(height: 10),

          // Opción 2: Publicar directo en Universo
          if (onPublishToUniverse != null) ...[
            _buildDecisionTile(
              context,
              icon: Icons.public,
              color: AppColors.cultura,
              title: '2. Inyección Directa en Universo',
              description:
                  'Registra el proyecto en universe.json con sus URLs actuales sin modificar código ni generar assets pesados.',
              onTap: onPublishToUniverse,
            ),
            const SizedBox(height: 10),
          ],

          // Opción 3: Guardar en Registry local
          _buildDecisionTile(
            context,
            icon: Icons.save_outlined,
            color: AppColors.herramientas,
            title: '3. Guardar en Registry Local',
            description:
                'Guarda el registro de análisis en SQLite local para seguimiento de versiones y salud del código sin publicar.',
            onTap: onSaveToRegistry,
          ),
          const SizedBox(height: 10),

          // Opción 4: Continuar desarrollo / Mantener en INBOX
          _buildDecisionTile(
            context,
            icon: Icons.code_rounded,
            color: AppColors.educacion,
            title: '4. Continuar Desarrollo',
            description:
                'Mantiene el proyecto activo en INBOX/ y abre la terminal contextual para seguir programándolo con Coding Agents.',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Proyecto listo en INBOX/ para continuar desarrollo 💻'),
                  duration: Duration(milliseconds: 1000),
                  backgroundColor: AppColors.educacion,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ),
        trailing: onTap != null
            ? ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Elegir'),
              )
            : null,
      ),
    );
  }
}

