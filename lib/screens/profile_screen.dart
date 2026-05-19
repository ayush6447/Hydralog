import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/water_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _showEditProfileDialog(BuildContext context, WaterProvider provider) async {
    final profile = provider.profile;
    final nameController = TextEditingController(text: profile.name);
    final ageController = TextEditingController(text: profile.age.toString());
    final heightController = TextEditingController(text: profile.height.toStringAsFixed(1));
    final weightController = TextEditingController(text: profile.weight.toStringAsFixed(1));

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                textCapitalization: TextCapitalization.words,
              ),
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
              ),
              TextField(
                controller: heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Height (cm)'),
              ),
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              final newAge = int.tryParse(ageController.text);
              final newHeight = double.tryParse(heightController.text);
              final newWeight = double.tryParse(weightController.text);

              if (newName.isEmpty || newAge == null || newHeight == null || newWeight == null ||
                  newAge <= 0 || newHeight <= 0 || newWeight <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid values.')),
                );
                return;
              }

              final newProfile = UserProfile(
                name: newName,
                age: newAge,
                height: newHeight,
                weight: newWeight,
              );

              // Ask if they want to auto-update their goal
              Navigator.pop(context);
              _askAutoUpdateGoal(context, provider, newProfile);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _askAutoUpdateGoal(
      BuildContext context, WaterProvider provider, UserProfile newProfile) async {
    final recommended = newProfile.recommendedGoalMl;
    if (recommended == provider.goal) {
      provider.updateProfile(newProfile);
      return;
    }
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update Daily Goal?'),
        content: Text(
          'Based on your weight, your recommended daily intake is '
          '${(recommended / 1000).toStringAsFixed(1)} L.\n\nUpdate your goal?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.updateProfile(newProfile, autoUpdateGoal: false);
              Navigator.pop(context);
            },
            child: const Text('Keep current'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.updateProfile(newProfile, autoUpdateGoal: true);
              Navigator.pop(context);
            },
            child: const Text('Update goal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterProvider>(
      builder: (context, provider, _) {
        final profile = provider.profile;
        final streak = provider.currentStreak;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Profile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
              ),
              const SizedBox(height: 20),

              if (profile.name.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.cyanAccent, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Set up your profile to get a personalised hydration goal.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              if (profile.name.isEmpty) const SizedBox(height: 16),

              _profileRow('Name', profile.name.isEmpty ? '—' : profile.name),
              _profileRow('Age', '${profile.age} yrs'),
              _profileRow('Height', '${profile.height.toStringAsFixed(1)} cm'),
              _profileRow('Weight', '${profile.weight.toStringAsFixed(1)} kg'),
              _profileRow('Daily Goal', '${(provider.goal / 1000).toStringAsFixed(1)} L'),
              _profileRow(
                'Recommended',
                '${(profile.recommendedGoalMl / 1000).toStringAsFixed(1)} L',
                subtitle: 'based on your weight',
              ),

              const Divider(color: Colors.white12, height: 32),

              // Stats
              const Text(
                'Stats',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
              ),
              const SizedBox(height: 12),
              _profileRow('Current Streak', streak > 0 ? '🔥 $streak days' : '—'),
              _profileRow('Total Days Logged', '${provider.historyMap.length}'),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showEditProfileDialog(context, provider),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Reset Data'),
                        content: const Text('This will clear today\'s intake and all history. This cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            onPressed: () {
                              provider.resetData();
                              Navigator.pop(context);
                            },
                            child: const Text('Reset', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset Intake & History'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _profileRow(String label, String value, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
              if (subtitle != null)
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
