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

  static const List<String> _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const List<String> _monthShortNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  int _daysInMonth(DateTime month) {
    final next = month.month < 12
        ? DateTime(month.year, month.month + 1, 1)
        : DateTime(month.year + 1, 1, 1);
    return next.subtract(const Duration(days: 1)).day;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterProvider>(
      builder: (context, provider, _) {
        final daysCount = _daysInMonth(_currentMonth);
        final firstWeekday = _currentMonth.weekday % 7; // 0 = Sunday

        final bool hasAnyData = List.generate(daysCount, (i) {
          final date = DateTime(_currentMonth.year, _currentMonth.month, i + 1);
          return provider.intakeForDate(date);
        }).any((v) => v > 0);

        List<Widget> dayWidgets = List.generate(firstWeekday, (_) => const SizedBox());

        for (int day = 1; day <= daysCount; day++) {
          final date = DateTime(_currentMonth.year, _currentMonth.month, day);
          final intake = provider.intakeForDate(date);
          final isToday = DateUtils.isSameDay(date, DateTime.now());
          final ratio = (intake / provider.goal).clamp(0.0, 1.0);

          dayWidgets.add(GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('$day ${_monthShortNames[date.month - 1]}'),
                  content: intake == 0
                      ? const Text('No data recorded for this day.')
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Intake: ${(intake / 1000).toStringAsFixed(2)} L'),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: ratio,
                              color: Colors.cyanAccent,
                              backgroundColor: Colors.white10,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ratio >= 1.0 ? '✅ Goal met!' : '${(ratio * 100).toInt()}% of goal',
                              style: TextStyle(
                                color: ratio >= 1.0 ? Colors.tealAccent : Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                  ],
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isToday
                    ? Colors.tealAccent.withOpacity(0.85)
                    : intake > 0
                        ? Colors.cyanAccent.withOpacity(0.25 + ratio * 0.55)
                        : Colors.white10,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isToday ? Colors.tealAccent : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  if (isToday)
                    BoxShadow(
                      color: Colors.tealAccent.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                ],
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      color: isToday ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (intake > 0)
                    Text(
                      '${(intake / 1000).toStringAsFixed(1)}L',
                      style: TextStyle(
                        color: isToday ? Colors.black87 : Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ));
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Month navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.month == 1 ? _currentMonth.year - 1 : _currentMonth.year,
                        _currentMonth.month == 1 ? 12 : _currentMonth.month - 1,
                      );
                    }),
                    icon: const Icon(Icons.chevron_left, color: Colors.cyanAccent),
                  ),
                  Text(
                    DateFormat.yMMMM().format(_currentMonth),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.month == 12 ? _currentMonth.year + 1 : _currentMonth.year,
                        _currentMonth.month == 12 ? 1 : _currentMonth.month + 1,
                      );
                    }),
                    icon: const Icon(Icons.chevron_right, color: Colors.cyanAccent),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Weekday headers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _weekdays
                    .map((d) => SizedBox(
                          width: 36,
                          child: Center(
                            child: Text(
                              d,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),

              // Calendar grid or empty state
              Expanded(
                child: hasAnyData
                    ? GridView.count(
                        crossAxisCount: 7,
                        children: dayWidgets,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GridView.count(
                            crossAxisCount: 7,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: dayWidgets,
                          ),
                          const SizedBox(height: 24),
                          const Icon(Icons.water_drop_outlined, size: 48, color: Colors.white24),
                          const SizedBox(height: 12),
                          const Text(
                            'No data this month.\nStart logging water on the Home tab!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white38, fontSize: 14),
                          ),
                        ],
                      ),
              ),

              // Legend
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legendDot(Colors.white10, 'No data'),
                    const SizedBox(width: 16),
                    _legendDot(Colors.cyanAccent.withOpacity(0.5), 'Partial'),
                    const SizedBox(width: 16),
                    _legendDot(Colors.cyanAccent, 'Goal met'),
                    const SizedBox(width: 16),
                    _legendDot(Colors.tealAccent.withOpacity(0.85), 'Today'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
