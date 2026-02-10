import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/resident_provider.dart';
import '../../config/theme.dart';

class ProfileScreenModern extends ConsumerWidget {
  const ProfileScreenModern({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final residentAsync = ref.watch(currentResidentProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            ),
          ),
        ),
      ),
      body: residentAsync.when(
        data: (resident) => _buildProfile(context, ref, resident),
        loading: () => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ).animate().fadeIn().scale(),
        ),
        error: (error, stack) => Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading profile',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ).animate().fadeIn().scale(),
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, WidgetRef ref, resident) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: 120,
        bottom: 100,
        left: 24,
        right: 24,
      ),
      child: Column(
        children: [
          // Profile Avatar
          Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: 100.ms)
              .scale(begin: const Offset(0.8, 0.8)),

          const SizedBox(height: 24),

          // User Name
          Text(
            resident?.name ?? 'Anonymous',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.1, end: 0),

          const SizedBox(height: 24),

          // Stats Cards
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildStatRow(
                  icon: Icons.apartment,
                  label: 'Floor',
                  value: '${resident?.floor ?? 0}',
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatRow(
                  icon: Icons.star,
                  label: 'Experience',
                  value: '${resident?.experienceLevel ?? 0}',
                  gradient: LinearGradient(
                    colors: [Colors.amber, Colors.orange],
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatRow(
                  icon: Icons.credit_score,
                  label: 'Credits',
                  value: '${resident?.creditScore ?? 0}',
                  gradient: LinearGradient(colors: [Colors.green, Colors.teal]),
                ),
                const SizedBox(height: 16),
                _buildStatRow(
                  icon: Icons.message,
                  label: 'Messages',
                  value: '${resident?.messageCount ?? 0}',
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.3),
                            AppTheme.secondaryColor.withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Your floor level determines your privileges in the apartment building',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 32),

          // Sign Out Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.red.shade400, Colors.red.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go('/welcome');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Gradient gradient,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
