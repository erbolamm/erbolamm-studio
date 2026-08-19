import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: AppColors.herramientas),
            SizedBox(width: 8),
            Text('Panel de Admin'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCards(),
            const SizedBox(height: 24),
            _buildSectionTitle('Gestión de usuarios'),
            const SizedBox(height: 12),
            _buildUserList(),
            const SizedBox(height: 24),
            _buildSectionTitle('Roadmap pública'),
            const SizedBox(height: 12),
            _buildRoadmapEditor(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Usuarios',
            '28',
            Icons.people,
            AppColors.educacion,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Proyectos',
            '32',
            Icons.folder,
            AppColors.ia,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Ingresos',
            '€0',
            Icons.euro,
            AppColors.cultura,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildUserList() {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.educacion,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: const Text(
          'Javier Mateo',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        subtitle: const Text(
          'erbolamm@gmail.com',
          style: TextStyle(color: AppColors.textMuted),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.ia.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Admin',
            style: TextStyle(
              color: AppColors.ia,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoadmapEditor() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items de la roadmap',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildRoadmapItem('Chat Bolabot funcional', 'En progreso'),
            _buildRoadmapItem('Interacción Sims entre naves', 'Pendiente'),
            _buildRoadmapItem('Code splitting', 'Pendiente'),
            _buildRoadmapItem('Dominio erbolamm.com', 'Completado'),
          ],
        ),
      ),
    );
  }

  Widget _buildRoadmapItem(String title, String status) {
    final statusColor = status == 'Completado'
        ? AppColors.cultura
        : status == 'En progreso'
            ? AppColors.herramientas
            : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
