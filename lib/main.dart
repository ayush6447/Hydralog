import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() => runApp(const WaterTrackerApp());

class WaterTrackerApp extends StatelessWidget {
  const WaterTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Tracker',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.tealAccent,
        ),
      ),
      home: const WaterTrackerHomePage(),
    );
  }
}

class WaterTrackerHomePage extends StatefulWidget {
  const WaterTrackerHomePage({super.key});

  @override
  State<WaterTrackerHomePage> createState() => _WaterTrackerHomePageState();
}

class _WaterTrackerHomePageState extends State<WaterTrackerHomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int _currentIntake = 0;
  int _previousIntake = 0;
  int _goal = 3000;
  Map<String, int> _historyMap = {};

  String name = 'John Doe';
  int age = 25;
  double height = 170.0;
  double weight = 70.0;

  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _progressAnimationController, curve: Curves.easeOut));
    _loadData();
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIntake = prefs.getInt('intake') ?? 0;
      _previousIntake = _currentIntake;
      _goal = prefs.getInt('goal') ?? 3000;
      final List<String>? keys = prefs.getStringList('history_keys');
      final List<String>? values = prefs.getStringList('history_values');
      if (keys != null && values != null && keys.length == values.length) {
        _historyMap = {
          for (int i = 0; i < keys.length; i++) keys[i]: int.tryParse(values[i]) ?? 0
        };
      } else {
        _historyMap = {};
      }

      name = prefs.getString('name') ?? 'John Doe';
      age = prefs.getInt('age') ?? 25;
      height = prefs.getDouble('height') ?? 170.0;
      weight = prefs.getDouble('weight') ?? 70.0;

      _animateProgress();
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('intake', _currentIntake);
    await prefs.setInt('goal', _goal);
    await prefs.setStringList('history_keys', _historyMap.keys.toList());
    await prefs.setStringList('history_values', _historyMap.values.map((e) => e.toString()).toList());

    await prefs.setString('name', name);
    await prefs.setInt('age', age);
    await prefs.setDouble('height', height);
    await prefs.setDouble('weight', weight);
  }

  void _animateProgress() {
    double startProgress = (_previousIntake / _goal).clamp(0.0, 1.0);
    double endProgress = (_currentIntake / _goal).clamp(0.0, 1.0);

    _progressAnimationController.reset();
    _progressAnimation = Tween<double>(begin: startProgress, end: endProgress).animate(
      CurvedAnimation(parent: _progressAnimationController, curve: Curves.easeInOut),
    );
    _progressAnimationController.forward();

    _previousIntake = _currentIntake;
  }

  void _addWater(int amount) {
    setState(() {
      _currentIntake += amount;
      String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _historyMap[todayKey] = (_historyMap[todayKey] ?? 0) + amount;
    });
    _animateProgress();
    _saveData();
  }

  void _removeWater(int amount) {
    setState(() {
      _currentIntake = (_currentIntake - amount).clamp(0, _goal);
      String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      int currentDayIntake = _historyMap[todayKey] ?? 0;
      int newDayIntake = (currentDayIntake - amount).clamp(0, _goal);
      _historyMap[todayKey] = newDayIntake;
    });
    _animateProgress();
    _saveData();
  }

  Future<void> _showSetGoalDialog() async {
    final controller = TextEditingController(text: (_goal / 1000).toString());
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Daily Goal (Liters)'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Enter liters, e.g. 3.5',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                setState(() {
                  _goal = (val * 1000).toInt();
                  if (_currentIntake > _goal) {
                    _currentIntake = _goal;
                  }
                });
                _animateProgress();
                _saveData();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(text: name);
    final ageController = TextEditingController(text: age.toString());
    final heightController = TextEditingController(text: height.toString());
    final weightController = TextEditingController(text: weight.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
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

              if (newName.isNotEmpty && newAge != null && newAge > 0 && newHeight != null && newHeight > 0 && newWeight != null && newWeight > 0) {
                setState(() {
                  name = newName;
                  age = newAge;
                  height = newHeight;
                  weight = newWeight;
                });
                _saveData();
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid values.')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetData() async {
    setState(() {
      _currentIntake = 0;
      _historyMap.clear();
    });
    _animateProgress();
    _saveData();
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: _currentIntake / 1000),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Text(
                '${value.toStringAsFixed(1)} / ${(_goal / 1000).toStringAsFixed(1)} L',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
              );
            },
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _progressAnimationController,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value.clamp(0, 1),
                color: Colors.cyanAccent,
                backgroundColor: Colors.white10,
                minHeight: 12,
              );
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showSetGoalDialog,
            icon: const Icon(Icons.flag),
            label: const Text('Set Daily Goal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 4,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Add Water Intake',
            style: TextStyle(fontSize: 20, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _animatedIntakeButton('500 ml', 500),
              _animatedIntakeButton('750 ml', 750),
              _animatedIntakeButton('1 L', 1000),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _removeWater(500),
            icon: const Icon(Icons.remove),
            label: const Text('Remove 500ml'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedIntakeButton(String label, int amount) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.tealAccent.withOpacity(0.3),
      onTap: () {
        _addWater(amount);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.cyanAccent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.6),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_drink, color: Colors.black),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.black)),
          ],
        ),
      ),
    );
  }

  int _daysInMonth(DateTime month) {
    var beginningNextMonth = (month.month < 12)
        ? DateTime(month.year, month.month + 1, 1)
        : DateTime(month.year + 1, 1, 1);
    return beginningNextMonth.subtract(const Duration(days: 1)).day;
  }

  Widget _buildHistoryPage() {
    int daysCount = _daysInMonth(_currentMonth);
    int firstWeekday = _currentMonth.weekday;
    int leadingEmptyDays = (firstWeekday % 7);

    List<Widget> dayWidgets = [];

    for (int i = 0; i < leadingEmptyDays; i++) {
      dayWidgets.add(Container());
    }

    for (int day = 1; day <= daysCount; day++) {
      DateTime date = DateTime(_currentMonth.year, _currentMonth.month, day);
      String key = DateFormat('yyyy-MM-dd').format(date);
      int intake = _historyMap[key] ?? 0;
      bool isToday = DateTime.now().year == date.year &&
          DateTime.now().month == date.month &&
          DateTime.now().day == date.day;
      double intakeRatio = intake / _goal;
      if (intakeRatio > 1.0) intakeRatio = 1.0;

      dayWidgets.add(GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Intake on $day ${_monthShort(date.month)}'),
              content: Text('You drank ${(intake / 1000).toStringAsFixed(2)} L on this day.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ],
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isToday
                ? Colors.tealAccent.withOpacity(0.8)
                : intakeRatio > 0
                ? Colors.cyanAccent.withOpacity(0.6 + intakeRatio * 0.4)
                : Colors.white10,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isToday ? Colors.tealAccent : Colors.transparent, width: 2),
            boxShadow: [
              if (isToday)
                BoxShadow(
                  color: Colors.tealAccent.withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 2,
                )
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
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              if (intake > 0)
                Text(
                  '${(intake / 1000).toStringAsFixed(1)}L',
                  style: TextStyle(
                    color: isToday ? Colors.black87 : Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Previous Month',
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.month == 1 ? _currentMonth.year - 1 : _currentMonth.year,
                      _currentMonth.month == 1 ? 12 : _currentMonth.month - 1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_left, color: Colors.cyanAccent),
              ),
              Text(
                DateFormat.yMMMM().format(_currentMonth),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
              ),
              IconButton(
                tooltip: 'Next Month',
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.month == 12 ? _currentMonth.year + 1 : _currentMonth.year,
                      _currentMonth.month == 12 ? 1 : _currentMonth.month + 1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_right, color: Colors.cyanAccent),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _WeekdayLabel(label: 'Sun'),
              _WeekdayLabel(label: 'Mon'),
              _WeekdayLabel(label: 'Tue'),
              _WeekdayLabel(label: 'Wed'),
              _WeekdayLabel(label: 'Thu'),
              _WeekdayLabel(label: 'Fri'),
              _WeekdayLabel(label: 'Sat'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.count(
              crossAxisCount: 7,
              children: dayWidgets,
            ),
          ),
        ],
      ),
    );
  }

  static const List<String> _monthShortNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _monthShort(int month) {
    if (month >= 1 && month <= 12) {
      return _monthShortNames[month - 1];
    }
    return '';
  }

  Widget _buildProfilePage() {
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
          _profileRow('Name', name),
          _profileRow('Age', '$age'),
          _profileRow('Height', '${height.toStringAsFixed(1)} cm'),
          _profileRow('Weight', '${weight.toStringAsFixed(1)} kg'),
          _profileRow('Daily Goal', '${(_goal / 1000).toStringAsFixed(1)} L'),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _showEditProfileDialog,
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Data'),
                  content: const Text('Are you sure you want to reset intake and history?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () {
                        _resetData();
                        Navigator.pop(context);
                      },
                      child: const Text('Reset'),
                    )
                  ],
                ),
              );
            },
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset Intake & History'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildHistoryPage();
      case 2:
        return _buildProfilePage();
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Tracker'),
        backgroundColor: Colors.black,
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        onTap: (int index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;
  const _WeekdayLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

