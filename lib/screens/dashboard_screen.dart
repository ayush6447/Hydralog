import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/water_provider.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterProvider>(
      builder: (context, provider, _) {
        final h = provider.todayHealth;
        final user = AuthService.currentUser;
        final hour = DateTime.now().hour;
        final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
        final name = provider.profile.name.isNotEmpty
            ? provider.profile.name.split(' ').first
            : user?.displayName?.split(' ').first ?? '';

        return RefreshIndicator(
          color: const Color(0xFF30D158),
          backgroundColor: Colors.white,
          onRefresh: provider.refreshHealthData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Large nav title (Apple-style) ───────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting + (name.isNotEmpty ? ', $name' : ''),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formattedDate(),
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.5),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Summary ring card ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _SummaryRingCard(provider: provider),
                ),
              ),

              // ── Metric cards grid ────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  delegate: SliverChildListDelegate([
                    _MetricCard(
                      icon: Icons.directions_walk_rounded,
                      label: 'Steps',
                      value: _formatNum(h.steps),
                      unit: 'steps',
                      goal: '10,000 goal',
                      progress: (h.steps / 10000).clamp(0.0, 1.0),
                      color: const Color(0xFFFF9F0A),
                      device: h.deviceSource,
                    ),
                    _MetricCard(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Active calories',
                      value: h.caloriesBurned.toStringAsFixed(0),
                      unit: 'kcal',
                      goal: 'burned today',
                      progress: (h.caloriesBurned / 500).clamp(0.0, 1.0),
                      color: const Color(0xFFFF375F),
                      device: h.deviceSource,
                    ),
                    _MetricCard(
                      icon: Icons.bedtime_rounded,
                      label: 'Sleep',
                      value: h.sleepHours > 0
                          ? h.sleepHours.toStringAsFixed(1)
                          : '—',
                      unit: h.sleepHours > 0 ? 'hrs' : '',
                      goal: h.sleepHours >= 7
                          ? 'Well rested'
                          : 'Aim for 7+ hrs',
                      progress: (h.sleepHours / 8).clamp(0.0, 1.0),
                      color: const Color(0xFF5E5CE6),
                      device: h.deviceSource,
                    ),
                    _MetricCard(
                      icon: Icons.phone_android_rounded,
                      label: 'Screen time',
                      value: h.screenTimeHours > 0
                          ? h.screenTimeHours.toStringAsFixed(1)
                          : '—',
                      unit: h.screenTimeHours > 0 ? 'hrs' : '',
                      goal: h.deviceSource == 'iphone'
                          ? 'Not on iOS'
                          : 'Today\'s usage',
                      progress: (h.screenTimeHours / 6).clamp(0.0, 1.0),
                      color: const Color(0xFF64D2FF),
                      device: h.deviceSource,
                    ),
                  ]),
                ),
              ),

              // ── Streak banner ────────────────────────────────────────
              if (provider.currentStreak > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: _StreakBanner(streak: provider.currentStreak),
                  ),
                ),

              // ── Sync status ──────────────────────────────────────────
              if (provider.isSyncing)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF30D158)),
                          ),
                          const SizedBox(width: 10),
                          Text('Syncing across devices…',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = ['January','February','March','April','May','June',
        'July','August','September','October','November','December'];
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  String _formatNum(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : n.toString();
}

// ── Water summary ring card ───────────────────────────────────────────────────
class _SummaryRingCard extends StatefulWidget {
  final WaterProvider provider;
  const _SummaryRingCard({required this.provider});

  @override
  State<_SummaryRingCard> createState() => _SummaryRingCardState();
}

class _SummaryRingCardState extends State<_SummaryRingCard> {
  Future<void> _addWater(int ml) async {
    HapticFeedback.lightImpact();
    widget.provider.addWater(ml);
  }

  Future<void> _showCustom() async {
    final controller = TextEditingController();
    // Quick-pick presets shown inside the sheet
    const presets = [150, 200, 330, 400, 600];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Add water',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Type a custom amount or pick a preset',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Preset chips row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: presets.map((ml) {
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.provider.addWater(ml);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF64D2FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF64D2FF).withOpacity(0.25)),
                        ),
                        child: Text(
                          '$ml ml',
                          style: const TextStyle(
                            color: Color(0xFF64D2FF),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Custom amount input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.1), width: 0.5),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.2),
                              fontSize: 18),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Text(
                        'ml',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 15,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Add button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF64D2FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    final v = int.tryParse(controller.text);
                    if (v != null && v > 0) {
                      HapticFeedback.lightImpact();
                      widget.provider.addWater(v);
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Add',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.water_drop_rounded,
                  color: Color(0xFF64D2FF), size: 18),
              const SizedBox(width: 6),
              const Text('Hydration',
                  style: TextStyle(
                      color: Color(0xFF64D2FF),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.2)),
              const Spacer(),
              Text(
                '${(p.progressRatio * 100).toInt()}%',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Ring + stats row
          Row(
            children: [
              _WaterRing(progress: p.progressRatio),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(p.currentIntake / 1000).toStringAsFixed(1)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1),
                    ),
                    Text('of ${(p.goal / 1000).toStringAsFixed(1)} L goal',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14)),
                    const SizedBox(height: 16),
                    Text(
                      p.currentIntake >= p.goal
                          ? 'Goal reached!'
                          : '${((p.goal - p.currentIntake) / 1000).toStringAsFixed(1)} L remaining',
                      style: TextStyle(
                          color: p.currentIntake >= p.goal
                              ? const Color(0xFF30D158)
                              : Colors.white.withOpacity(0.4),
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick-add buttons
          Row(
            children: [
              _QuickAddBtn(label: '250 ml', onTap: () => _addWater(250)),
              const SizedBox(width: 8),
              _QuickAddBtn(label: '500 ml', onTap: () => _addWater(500)),
              const SizedBox(width: 8),
              _QuickAddBtn(label: '750 ml', onTap: () => _addWater(750)),
              const SizedBox(width: 8),
              _QuickAddBtn(label: '1 L', onTap: () => _addWater(1000)),
              const SizedBox(width: 8),
              _QuickAddBtn(
                label: '+ custom',
                onTap: _showCustom,
                isSecondary: true,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Remove water button
          Center(
            child: GestureDetector(
              onTap: _showRemoveDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 16),
                    SizedBox(width: 6),
                    Text('Remove water',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRemoveDialog() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Remove water',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Logged too much?',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 13)),
            const SizedBox(height: 20),
            ...[250, 500, 750].map((ml) => GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.provider.removeWater(ml);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF375F).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFFF375F).withOpacity(0.2)),
                    ),
                    child: Text(
                      '− $ml ml',
                      style: const TextStyle(
                          color: Color(0xFFFF375F),
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _WaterRing extends StatelessWidget {
  final double progress;
  const _WaterRing({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: CustomPaint(
        painter: _RingPainter(progress: progress),
        child: Center(
          child: Icon(
            Icons.water_drop_rounded,
            color: const Color(0xFF64D2FF).withOpacity(0.9),
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 8;
    const sw = 10.0;

    canvas.drawCircle(c, r, Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -pi / 2,
        2 * pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = const Color(0xFF64D2FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _QuickAddBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSecondary;
  const _QuickAddBtn(
      {required this.label, required this.onTap, this.isSecondary = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSecondary
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFF64D2FF).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSecondary
                  ? Colors.white.withOpacity(0.5)
                  : const Color(0xFF64D2FF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Metric card ───────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final String goal;
  final double progress;
  final Color color;
  final String device;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.goal,
    required this.progress,
    required this.color,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(unit,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            goal,
            style: TextStyle(
                color: Colors.white.withOpacity(0.35), fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Streak banner ─────────────────────────────────────────────────────────────
class _StreakBanner extends StatelessWidget {
  final int streak;
  const _StreakBanner({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9F0A).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: Color(0xFFFF9F0A), size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$streak-day streak',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
              ),
              Text(
                'Keep hitting your water goal',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
