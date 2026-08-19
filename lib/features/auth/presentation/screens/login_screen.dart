import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.educacion, AppColors.ia],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.auto_awesome, size: 64, color: Colors.white),
              ),
              const SizedBox(height: 32),
              const Text(
                'ErBolamm Studio',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Modo Local — Fábrica de Software Autónoma',
                style: TextStyle(fontSize: 16, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
