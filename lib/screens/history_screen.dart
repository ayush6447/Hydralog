import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/water_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  int _daysInMonth(DateTime m) {
    final next = m.month < 12
        ? DateTime(m.year, m.month + 1, 1)
        : DateTime(m.year + 1, 1, 1);
    return next.subtract(const Duration(days: 1)).day;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterProvider>(
      builder: (context, provider, _) {
        final days = _daysInMonth(_currentMonth);
        final firstWeekday = _currentMonth.weekday % 7;

        // Build weekly bar data
        final List<_WeekBar> weekBars = _buildWeekBars(provider);

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: const Text(
                  'History',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5),
                ),
              ),
            ),

            // ── Weekly bar chart ─────────────────────────────────────
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
                          const Icon(Icons.water_drop_rounded,
                              color: Color(0xFF64D2FF), size: 16),
                          const SizedBox(width: 6),
                          const Text('This week',
                              style: TextStyle(
                                  color: Color(0xFF64D2FF),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          const Spacer(),
                          Text(
                            'Goal: ${(provider.goal / 1000).toStringAsFixed(1)} L',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _WeekBarChart(bars: weekBars, goal: provider.goal),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Calendar card ─────────────────────────────────────────
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
                    children: [
                      // Month nav
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => setState(() {
                              _currentMonth = DateTime(
                                _currentMonth.month == 1
                                    ? _currentMonth.year - 1
                                    : _currentMonth.year,
                                _currentMonth.month == 1
                                    ? 12
                                    : _currentMonth.month - 1,
                              );
                            }),
                            icon: const Icon(Icons.chevron_left,
                                color: Color(0xFF64D2FF)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Text(
                            DateFormat.yMMMM().format(_currentMonth),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16),
                          ),
                          IconButton(
                            onPressed: () => setState(() {
                              _currentMonth = DateTime(
                                _currentMonth.month == 12
                                    ? _currentMonth.year + 1
                                    : _currentMonth.year,
                                _currentMonth.month == 12
                                    ? 1
                                    : _currentMonth.month + 1,
                              );
                            }),
                            icon: const Icon(Icons.chevron_right,
                                color: Color(0xFF64D2FF)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Weekday headers
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: _weekdays
                            .map((d) => SizedBox(
                                  width: 32,
                                  child: Center(
                                    child: Text(d,
                                        style: TextStyle(
                                            color: Colors.white.withOpacity(0.4),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),

                      // Calendar grid
                      GridView.count(
                        crossAxisCount: 7,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          ...List.generate(firstWeekday, (_) => const SizedBox()),
                          ...List.generate(days, (i) {
                            final date = DateTime(
                                _currentMonth.year, _currentMonth.month, i + 1);
                            final intake = provider.intakeForDate(date);
                            final isToday = DateUtils.isSameDay(date, DateTime.now());
                            final isFuture = date.isAfter(DateTime.now());
                            final ratio = (intake / provider.goal).clamp(0.0, 1.0);
                            final metGoal = intake >= provider.goal;

                            return GestureDetector(
                              onTap: isFuture
                                  ? null
                                  : () => _showDayDetail(context, date, intake,
                                      ratio, provider.goal),
                              child: Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isToday
                                      ? const Color(0xFF64D2FF)
                                      : metGoal
                                          ? const Color(0xFF30D158).withOpacity(0.8)
                                          : intake > 0
                                              ? const Color(0xFF64D2FF)
                                                  .withOpacity(0.1 + ratio * 0.3)
                                              : Colors.transparent,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: isToday
                                        ? Colors.black
                                        : isFuture
                                            ? Colors.white.withOpacity(0.2)
                                            : Colors.white,
                                    fontSize: 13,
                                    fontWeight: isToday
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legendDot(const Color(0xFF30D158), 'Goal met'),
                          const SizedBox(width: 16),
                          _legendDot(const Color(0xFF64D2FF).withOpacity(0.4), 'Partial'),
                          const SizedBox(width: 16),
                          _legendDot(const Color(0xFF64D2FF), 'Today'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }

  List<_WeekBar> _buildWeekBars(WaterProvider provider) {
    final now = DateTime.now();
    // Go back to the last Sunday
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    const dayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return List.generate(7, (i) {
      final date = startOfWeek.add(Duration(days: i));
      final intake = provider.intakeForDate(date);
      return _WeekBar(
        label: dayLetters[i],
        intake: intake,
        isToday: DateUtils.isSameDay(date, now),
        isFuture: date.isAfter(now),
      );
    });
  }

  void _showDayDetail(BuildContext context, DateTime date, int intake,
      double ratio, int goal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat.yMMMMd().format(date),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17),
            ),
            const SizedBox(height: 16),
            if (intake == 0)
              Text('No data recorded.',
                  style: TextStyle(color: Colors.white.withOpacity(0.5)))
            else ...[
              Text(
                '${(intake / 1000).toStringAsFixed(2)} L logged',
                style: const TextStyle(
                    color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      ratio >= 1.0 ? const Color(0xFF30D158) : const Color(0xFF64D2FF)),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ratio >= 1.0
                    ? 'Goal met!'
                    : '${(ratio * 100).toInt()}% of ${(goal / 1000).toStringAsFixed(1)} L goal',
                style: TextStyle(
                    color: ratio >= 1.0
                        ? const Color(0xFF30D158)
                        : Colors.white.withOpacity(0.5),
                    fontSize: 14),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
      ],
    );
  }
}

// ── Week bar chart ────────────────────────────────────────────────────────────
class _WeekBar {
  final String label;
  final int intake;
  final bool isToday;
  final bool isFuture;
  const _WeekBar(
      {required this.label,
      required this.intake,
      required this.isToday,
      required this.isFuture});
}

class _WeekBarChart extends StatelessWidget {
  final List<_WeekBar> bars;
  final int goal;
  const _WeekBarChart({required this.bars, required this.goal});

  @override
  Widget build(BuildContext context) {
    final maxIntake =
        bars.map((b) => b.intake).fold(0, (a, b) => a > b ? a : b);
    final chartMax = maxIntake > goal ? maxIntake.toDouble() : goal.toDouble();

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((bar) {
          final ratio = chartMax > 0 ? (bar.intake / chartMax) : 0.0;
          final metGoal = bar.intake >= goal;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          width: double.infinity,
                          height: bar.isFuture ? 0 : (80 * ratio).clamp(4, 80),
                          decoration: BoxDecoration(
                            color: bar.isToday
                                ? const Color(0xFF64D2FF)
                                : metGoal
                                    ? const Color(0xFF30D158)
                                    : const Color(0xFF64D2FF).withOpacity(0.35),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bar.label,
                    style: TextStyle(
                      color: bar.isToday
                          ? const Color(0xFF64D2FF)
                          : Colors.white.withOpacity(0.4),
                      fontSize: 12,
                      fontWeight: bar.isToday ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
