import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_provider.dart';
import '../widgets/circular_water_progress.dart';
import '../widgets/intake_button.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterProvider>(
      builder: (context, provider, _) {
        final h = provider.todayHealth;
        return RefreshIndicator(
          color: Colors.cyanAccent,
          backgroundColor: const Color(0xFF1E1E1E),
          onRefresh: provider.refreshHealthData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sync badge
                if (provider.isSyncing)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 12, height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent)),
                        SizedBox(width: 8),
                        Text('Syncing across devices…',
                          style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                      ],
                    ),
                  ),

                // Device source badge
                if (h.deviceSource != 'manual')
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      h.deviceSource == 'iphone'
                          ? '📱 iPhone health data'
                          : h.deviceSource == 'samsung'
                              ? '📱 Samsung health data'
                              : '📱 Merged from both devices',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),

                // ── Water ───────────────────────────────────────────────────
                _sectionTitle('Hydration'),
                const SizedBox(height: 12),
                Center(
                  child: CircularWaterProgress(
                    progress: provider.progressRatio,
                    currentMl: provider.currentIntake,
                    goalMl: provider.goal,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    IntakeButton(label: '250 ml', amount: 250, onTap: () => provider.addWater(250)),
                    IntakeButton(label: '500 ml', amount: 500, onTap: () => provider.addWater(500)),
                    IntakeButton(label: '750 ml', amount: 750, onTap: () => provider.addWater(750)),
                    IntakeButton(label: '1 L', amount: 1000, onTap: () => provider.addWater(1000)),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Health metrics ───────────────────────────────────────────
                _sectionTitle('Today\'s Health'),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _metricCard(
                      icon: Icons.directions_walk,
                      label: 'Steps',
                      value: _formatSteps(h.steps),
                      subtitle: h.steps >= 10000 ? '🎉 Goal reached!' : '${h.steps}/10,000',
                      color: Colors.tealAccent,
                    ),
                    _metricCard(
                      icon: Icons.local_fire_department,
                      label: 'Calories burned',
                      value: '${h.caloriesBurned.toStringAsFixed(0)} kcal',
                      subtitle: h.caloriesBurned > 0 ? 'Active today' : 'No data yet',
                      color: Colors.orangeAccent,
                    ),
                    _metricCard(
                      icon: Icons.bedtime,
                      label: 'Sleep',
                      value: h.sleepHours > 0
                          ? '${h.sleepHours.toStringAsFixed(1)} hrs'
                          : '—',
                      subtitle: h.sleepHours >= 7
                          ? '😴 Well rested'
                          : h.sleepHours > 0
                              ? 'Aim for 7+ hrs'
                              : 'No data yet',
                      color: Colors.purpleAccent,
                    ),
                    _metricCard(
                      icon: Icons.phone_android,
                      label: 'Screen time',
                      value: h.screenTimeHours > 0
                          ? '${h.screenTimeHours.toStringAsFixed(1)} hrs'
                          : '—',
                      subtitle: h.deviceSource == 'iphone'
                          ? 'Not available on iOS'
                          : h.screenTimeHours > 0
                              ? 'Samsung usage'
                              : 'Samsung only',
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Streak
                if (provider.currentStreak > 0) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${provider.currentStreak}-day streak!',
                              style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                            const Text('Keep hitting your water goal',
                                style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Center(
                  child: Text(
                    'Pull down to refresh health data',
                    style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.cyanAccent,
            letterSpacing: 0.5));
  }

  Widget _metricCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text(subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) return '${(steps / 1000).toStringAsFixed(1)}k';
    return steps.toString();
  }
}
