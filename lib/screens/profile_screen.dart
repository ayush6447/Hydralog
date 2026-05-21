import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/water_provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    return Consumer<WaterProvider>(
      builder: (context, provider, _) {
        final profile = provider.profile;
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: const Text('Profile',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5)),
              ),
            ),

            // ── Account card ─────────────────────────────────────────
            if (user != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              const Color(0xFF64D2FF).withOpacity(0.15),
                          backgroundImage: user.photoURL != null
                              ? NetworkImage(user.photoURL!)
                              : null,
                          child: user.photoURL == null
                              ? Text(
                                  (user.displayName ?? '?')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      color: Color(0xFF64D2FF),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20))
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.displayName ?? 'User',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16)),
                              const SizedBox(height: 2),
                              Text(user.email ?? '',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.45),
                                      fontSize: 13)),
                              const SizedBox(height: 6),
                              Row(children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                      color: Color(0xFF30D158),
                                      shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 5),
                                Text('Syncing across devices',
                                    style: TextStyle(
                                        color: const Color(0xFF30D158)
                                            .withOpacity(0.8),
                                        fontSize: 12)),
                              ]),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.logout_rounded,
                              color: Colors.white.withOpacity(0.3), size: 20),
                          onPressed: () => _confirmSignOut(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Stats row ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(
                    child: _statCard('Streak',
                        provider.currentStreak > 0
                            ? '${provider.currentStreak}d'
                            : '—',
                        const Color(0xFFFF9F0A)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                        'Days logged',
                        '${provider.historyMap.length}',
                        const Color(0xFF64D2FF)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                        'Daily goal',
                        '${(provider.goal / 1000).toStringAsFixed(1)} L',
                        const Color(0xFF30D158)),
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Body stats ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      _settingsRow('Name',
                          profile.name.isEmpty ? 'Not set' : profile.name),
                      _divider(),
                      _settingsRow('Age', '${profile.age} yrs'),
                      _divider(),
                      _settingsRow('Height',
                          '${profile.height.toStringAsFixed(0)} cm'),
                      _divider(),
                      _settingsRow('Weight',
                          '${profile.weight.toStringAsFixed(1)} kg'),
                      _divider(),
                      _settingsRow(
                          'Recommended intake',
                          '${(profile.recommendedGoalMl / 1000).toStringAsFixed(1)} L',
                          subtitle: 'based on weight × 35 ml/kg'),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Actions ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      _actionRow(
                        context,
                        Icons.edit_rounded,
                        'Edit profile',
                        const Color(0xFF64D2FF),
                        () => _showEditDialog(context, provider),
                      ),
                      _divider(),
                      _actionRow(
                        context,
                        Icons.flag_rounded,
                        'Set daily goal',
                        const Color(0xFF30D158),
                        () => _showGoalDialog(context, provider),
                      ),
                      _divider(),
                      _actionRow(
                        context,
                        Icons.notifications_active_rounded,
                        'Test notification',
                        const Color(0xFF5E5CE6),
                        () => _triggerTestNotification(context),
                      ),
                      _divider(),
                      _actionRow(
                        context,
                        Icons.restart_alt_rounded,
                        'Reset data',
                        const Color(0xFFFF375F),
                        () => _confirmReset(context, provider),
                        destructive: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),


            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Developer card ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF64D2FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.code_rounded,
                                color: Color(0xFF64D2FF), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Built by Ayush',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                              Text('FlowTrack v2.0.0',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(
                          height: 0.5,
                          thickness: 0.5,
                          color: Colors.white.withOpacity(0.08)),
                      const SizedBox(height: 14),
                      _devLink(
                        Icons.logo_dev_rounded,
                        'GitHub',
                        'ayush6447',
                        'github.com/ayush6447',
                        const Color(0xFFE6EDF3),
                      ),
                      const SizedBox(height: 10),
                      _devLink(
                        Icons.work_rounded,
                        'LinkedIn',
                        'Ayush Kumar',
                        'linkedin.com/in/ayush6447',
                        const Color(0xFF0A66C2),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── What is coming next ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF30D158).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.rocket_launch_rounded,
                                color: Color(0xFF30D158), size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Text("What is coming",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _roadmapItem('Heart rate monitoring',
                          'Read resting and active BPM from both devices'),
                      _roadmapItem('Workout logging',
                          'Log runs, gym sessions and track calories burned'),
                      _roadmapItem('Weekly health report',
                          'Auto-generated PDF summary every Sunday'),
                      _roadmapItem('AI hydration coach',
                          'Personalised tips based on your activity and weather'),
                      _roadmapItem('Weather-aware goals',
                          'Raise water goal automatically on hot days'),
                      _roadmapItem('Friends and challenges',
                          'Compete on daily step and hydration leaderboards'),
                      _roadmapItem('Wear OS and watchOS',
                          'Log water and see stats from your wrist'),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _settingsRow(String label, String value, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 15)),
            if (subtitle != null)
              Text(subtitle,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35), fontSize: 11)),
          ]),
          Text(value,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 15)),
        ],
      ),
    );
  }

  Widget _actionRow(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap,
      {bool destructive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    color: destructive ? const Color(0xFFFF375F) : Colors.white,
                    fontSize: 15)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.25), size: 20),
          ],
        ),
      ),
    );
  }


  Widget _devLink(IconData icon, String platform, String handle,
      String url, Color color) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(platform,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
            Text(url,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.35), fontSize: 12)),
          ],
        ),
        const Spacer(),
        Icon(Icons.arrow_outward_rounded,
            color: Colors.white.withOpacity(0.2), size: 16),
      ],
    );
  }

  Widget _roadmapItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF30D158).withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 12,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.only(left: 18),
        child: Divider(
            height: 0.5,
            thickness: 0.5,
            color: Colors.white.withOpacity(0.08)),
      );

  void _showEditDialog(BuildContext context, WaterProvider provider) {
    final profile = provider.profile;
    final nameC = TextEditingController(text: profile.name);
    final ageC = TextEditingController(text: profile.age.toString());
    final heightC =
        TextEditingController(text: profile.height.toStringAsFixed(0));
    final weightC =
        TextEditingController(text: profile.weight.toStringAsFixed(1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit profile',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20)),
            const SizedBox(height: 20),
            _field(nameC, 'Name'),
            const SizedBox(height: 12),
            _field(ageC, 'Age', number: true),
            const SizedBox(height: 12),
            _field(heightC, 'Height (cm)', number: true),
            const SizedBox(height: 12),
            _field(weightC, 'Weight (kg)', decimal: true),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF64D2FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  final name = nameC.text.trim();
                  final age = int.tryParse(ageC.text);
                  final height = double.tryParse(heightC.text);
                  final weight = double.tryParse(weightC.text);
                  if (name.isEmpty || age == null || height == null ||
                      weight == null) return;
                  provider.updateProfile(UserProfile(
                      name: name, age: age, height: height, weight: weight),
                      autoUpdateGoal: true);
                  Navigator.pop(context);
                },
                child: const Text('Save',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {bool number = false, bool decimal = false}) {
    return TextField(
      controller: c,
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : number
              ? TextInputType.number
              : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: Colors.white.withOpacity(0.12))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF64D2FF))),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
      ),
    );
  }

  void _showGoalDialog(BuildContext context, WaterProvider provider) {
    final c = TextEditingController(
        text: (provider.goal / 1000).toStringAsFixed(1));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daily goal (litres)',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20)),
            const SizedBox(height: 8),
            Text(
                'Recommended: ${(provider.profile.recommendedGoalMl / 1000).toStringAsFixed(1)} L',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 13)),
            const SizedBox(height: 20),
            _field(c, 'Goal in litres', decimal: true),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                provider.setGoal(provider.profile.recommendedGoalMl);
                Navigator.pop(context);
              },
              child: const Text('Use recommended',
                  style: TextStyle(color: Color(0xFF64D2FF))),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF30D158),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  final v = double.tryParse(c.text);
                  if (v != null && v > 0) {
                    provider.setGoal((v * 1000).toInt());
                    Navigator.pop(context);
                  }
                },
                child: const Text('Set goal',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Sign out?',
            style: TextStyle(color: Colors.white)),
        content: Text(
            'Your data is safely stored in the cloud.',
            style: TextStyle(color: Colors.white.withOpacity(0.6))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: Colors.white.withOpacity(0.5)))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.signOut();
            },
            child: const Text('Sign out',
                style: TextStyle(color: Color(0xFFFF375F))),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, WaterProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Reset data?',
            style: TextStyle(color: Colors.white)),
        content: Text(
            'This clears local history. Cloud data is preserved.',
            style: TextStyle(color: Colors.white.withOpacity(0.6))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: Colors.white.withOpacity(0.5)))),
          TextButton(
            onPressed: () {
              provider.resetData();
              Navigator.pop(context);
            },
            child: const Text('Reset',
                style: TextStyle(color: Color(0xFFFF375F))),
          ),
        ],
      ),
    );
  }

  void _triggerTestNotification(BuildContext context) async {
    try {
      // Gather diagnostics
      final permStatus = await NotificationService.getPermissionStatus();
      final pending = await NotificationService.getPendingNotifications();

      // Send the instant notification
      await NotificationService.sendInstantNotification();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Notification sent! Permission: $permStatus | Pending: ${pending.length}'),
            backgroundColor: const Color(0xFF30D158),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed: $e'),
            backgroundColor: const Color(0xFFFF375F),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
