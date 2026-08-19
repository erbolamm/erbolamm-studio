import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import 'providers_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Ajustes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Preferencias'),
            const SizedBox(height: 12),
            _buildPreferencesList(),
            const SizedBox(height: 24),
            _buildSectionTitle('Proveedores IA'),
            const SizedBox(height: 12),
            _buildProvidersCard(context),
            const SizedBox(height: 24),
            _buildSectionTitle('Información'),
            const SizedBox(height: 12),
            _buildInfoCard(),
          ],
        ),
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

  Widget _buildPreferencesList() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text(
              'Modo Oscuro ApliArte',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            subtitle: const Text(
              'Usar el tema oscuro de alto contraste',
              style: TextStyle(color: AppColors.textMuted),
            ),
            value: true,
            onChanged: (bool value) {},
          ),
          const Divider(color: AppColors.border),
          SwitchListTile(
            title: const Text(
              'Notificaciones',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            subtitle: const Text(
              'Recibir avisos de estado del pipeline',
              style: TextStyle(color: AppColors.textMuted),
            ),
            value: true,
            onChanged: (bool value) {},
          ),
        ],
      ),
    );
  }

  Widget _buildProvidersCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.psychology, color: AppColors.ia),
        title: const Text(
          'Configurar Proveedores IA',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text(
          'DeepSeek, MiniMax, Claude, OpenAI, Gemini, Groq, NVIDIA',
          style: TextStyle(color: AppColors.textMuted),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProvidersScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ErBolamm Studio · Local & Open Source',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Versión 1.0.0 (Build 2026) · Licencia MIT © Javier Mateo',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
