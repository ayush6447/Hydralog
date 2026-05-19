import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_provider.dart';
import '../widgets/intake_button.dart';
import '../widgets/circular_water_progress.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _showSetGoalDialog(BuildContext context, WaterProvider provider) async {
    final controller = TextEditingController(text: (provider.goal / 1000).toStringAsFixed(1));
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Daily Goal (Liters)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'e.g. 2.5'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Text(
              'Recommended for your weight: ${(provider.profile.recommendedGoalMl / 1000).toStringAsFixed(1)} L',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.setGoal(provider.profile.recommendedGoalMl);
              Navigator.pop(context);
            },
            child: const Text('Use Recommended'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                provider.setGoal((val * 1000).toInt());
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomAmountDialog(BuildContext context, WaterProvider provider) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Amount (ml)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'e.g. 250'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                provider.addWater(val);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRemoveDialog(BuildContext context, WaterProvider provider) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Water'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [250, 500, 750].map((ml) => ListTile(
            leading: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
            title: Text('$ml ml'),
            onTap: () {
              provider.removeWater(ml);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterProvider>(
      builder: (context, provider, _) {
        final streak = provider.currentStreak;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (provider.profile.name.isNotEmpty)
                Text(
                  'Hey, ${provider.profile.name} 👋',
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
              const SizedBox(height: 12),

              // Streak badge
              if (streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.withOpacity(0.4)),
                  ),
                  child: Text(
                    '🔥 $streak-day streak!',
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 24),

              // Circular progress
              AnimatedBuilder(
                animation: const AlwaysStoppedAnimation(0),
                builder: (_, __) => CircularWaterProgress(
                  progress: provider.progressRatio,
                  currentMl: provider.currentIntake,
                  goalMl: provider.goal,
                ),
              ),
              const SizedBox(height: 28),

              // Set goal button
              OutlinedButton.icon(
                onPressed: () => _showSetGoalDialog(context, provider),
                icon: const Icon(Icons.flag, size: 18),
                label: const Text('Set Daily Goal'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.cyanAccent,
                  side: const BorderSide(color: Colors.cyanAccent),
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'Add Water',
                style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // Intake buttons
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  IntakeButton(label: '250 ml', amount: 250, onTap: () => provider.addWater(250)),
                  IntakeButton(label: '500 ml', amount: 500, onTap: () => provider.addWater(500)),
                  IntakeButton(label: '750 ml', amount: 750, onTap: () => provider.addWater(750)),
                  IntakeButton(label: '1 L', amount: 1000, onTap: () => provider.addWater(1000)),
                ],
              ),
              const SizedBox(height: 12),

              // Custom amount button
              TextButton.icon(
                onPressed: () => _showCustomAmountDialog(context, provider),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Custom amount'),
                style: TextButton.styleFrom(foregroundColor: Colors.white54),
              ),
              const SizedBox(height: 16),

              // Remove button
              OutlinedButton.icon(
                onPressed: () => _showRemoveDialog(context, provider),
                icon: const Icon(Icons.remove),
                label: const Text('Remove Water'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
