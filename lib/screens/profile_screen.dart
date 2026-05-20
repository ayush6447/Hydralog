import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/water_provider.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _showEditProfileDialog(
      BuildContext context, WaterProvider provider) async {
    final profile = provider.profile;
    final nameController = TextEditingController(text: profile.name);
    final ageController =
        TextEditingController(text: profile.age.toString());
    final heightController =
        TextEditingController(text: profile.height.toStringAsFixed(1));
    final weightController =
        TextEditingController(text: profile.weight.toStringAsFixed(1));

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                textCapitalization: TextCapitalization.words),
            TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age')),
            TextField(
                controller: heightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Height (cm)')),
            TextField(
                controller: weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Weight (kg)')),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              final newAge = int.tryParse(ageController.text);
              final newHeight = double.tryParse(heightController.text);
              final newWeight = double.tryParse(weightController.text);
              if (newName.isEmpty ||
                  newAge == null ||
                  newHeight == null ||
                  newWeight == null ||
                  newAge <= 0 ||
                  newHeight <= 0 ||
                  newWeight <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Please enter valid values.')));
                return;
              }
              final newProfile = UserProfile(
                  name: newName,
                  age: newAge,
                  height: newHeight,
                  weight: newWeight);
              Navigator.pop(context);
              _askAutoUpdateGoal(context, provider, newProfile);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _askAutoUpdateGoal(BuildContext context,
      WaterProvider provider, UserProfile newProfile) async {
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
            'Based on your weight, we recommend '
            '${(recommended / 1000).toStringAsFixed(1)} L/day.\n\nUpdate your goal?'),
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
    final user = AuthService.currentUser;
    return Consumer<WaterProvider>(
      builder: (context, provider, _) {
        final profile = provider.profile;
        final streak = provider.currentStreak;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Google account card
              if (user != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.07)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                        backgroundImage: user.photoURL != null
                            ? NetworkImage(user.photoURL!)
                            : null,
                        child: user.photoURL == null
                            ? Text(
                                (user.displayName ?? '?')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.displayName ?? 'User',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            Text(user.email ?? '',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 4),
                            const Row(children: [
                              Icon(Icons.sync, size: 12, color: Colors.tealAccent),
                              SizedBox(width: 4),
                              Text('Syncing across devices',
                                  style: TextStyle(
                                      color: Colors.tealAccent, fontSize: 11)),
                            ]),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white38),
                        onPressed: () => _confirmSignOut(context),
                      ),
                    ],
                  ),
                ),

              const Text('Your Profile',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent)),
              const SizedBox(height: 20),

              if (profile.name.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.cyanAccent.withOpacity(0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline, color: Colors.cyanAccent, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          'Set up your profile to get a personalised hydration goal.',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                  ]),
                ),

              _profileRow('Name',
                  profile.name.isEmpty ? '—' : profile.name),
              _profileRow('Age', '${profile.age} yrs'),
              _profileRow('Height',
                  '${profile.height.toStringAsFixed(1)} cm'),
              _profileRow('Weight',
                  '${profile.weight.toStringAsFixed(1)} kg'),
              _profileRow('Daily Goal',
                  '${(provider.goal / 1000).toStringAsFixed(1)} L'),
              _profileRow(
                'Recommended',
                '${(profile.recommendedGoalMl / 1000).toStringAsFixed(1)} L',
                subtitle: 'based on your weight',
              ),

              const Divider(color: Colors.white12, height: 32),

              const Text('Stats',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent)),
              const SizedBox(height: 12),
              _profileRow('Current Streak',
                  streak > 0 ? '🔥 $streak days' : '—'),
              _profileRow(
                  'Total Days Logged', '${provider.historyMap.length}'),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _showEditProfileDialog(context, provider),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmReset(context, provider),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset Intake & History'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content:
            const Text('Your data is safely stored in the cloud. You can sign back in anytime.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.signOut();
            },
            child:
                const Text('Sign out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, WaterProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Data'),
        content: const Text(
            'This will clear today\'s intake and all local history. Cloud data is preserved.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              provider.resetData();
              Navigator.pop(context);
            },
            child: const Text('Reset',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _profileRow(String label, String value, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 15)),
            if (subtitle != null)
              Text(subtitle,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11)),
          ]),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
