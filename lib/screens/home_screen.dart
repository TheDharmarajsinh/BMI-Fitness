import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/bmi_record.dart';
import '../widgets/custom_button.dart';
import 'history_screen.dart';
import 'tips_screen.dart';
import 'goal_screen.dart';
import 'trends_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedFeet = 5;
  int _selectedInches = 0;
  int _selectedWeight = 50;
  bool _useTextFieldInput = false; // Toggle between text field and dropdown
  final _formKey = GlobalKey<FormState>();
  final _feetController = TextEditingController();
  final _inchesController = TextEditingController();
  final _weightController = TextEditingController();
  double? _bmi;

  final double targetBmi = 22.0;
  late AnimationController _controller;

  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

  }

  Future<void> _calculateBmi() async {
    final heightInMeters = ((_selectedFeet * 12) + _selectedInches) * 0.0254;
    final bmi = _selectedWeight / (heightInMeters * heightInMeters);

    final bmiRecord = BmiRecord(
      bmi: bmi,
      height: heightInMeters * 100,
      weight: _selectedWeight.toDouble(),
      date: DateTime.now().toString(),
    );

    final dbHelper = DatabaseHelper();
    await dbHelper.insertBmiRecord(bmiRecord);

    setState(() {
      _bmi = bmi;
    });

    // Start slide down animation
    _slideController.forward();

    HapticFeedback.lightImpact();

    if (_bmi!.toStringAsFixed(1) == targetBmi.toStringAsFixed(1)) {
      _showAcknowledgmentDialog();
    }
  }

  String _getBmiCategory(double bmi) {
    if (bmi < 18.5) {
      return "Underweight";
    } else if (bmi < 24.9) {
      return "Normal weight";
    } else if (bmi < 29.9) {
      return "Overweight";
    } else {
      return "Obese";
    }
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) {
      return Colors.blue;
    } else if (bmi < 24.9) {
      return Colors.green;
    } else if (bmi < 29.9) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }

  void _showAcknowledgmentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Congratulations!',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
              'You have reached your BMI goal! Keep up the great work!'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _clearInputs() {
    setState(() {
      _selectedFeet = 5;
      _selectedInches = 0;
      _selectedWeight = 50;
      _bmi = null;
      _feetController.clear();
      _inchesController.clear();
      _weightController.clear();
    });
    HapticFeedback.mediumImpact();
  }

  void _switchInputMethod() {
    setState(() {
      _useTextFieldInput = !_useTextFieldInput;
      _clearInputs(); // Clear all values when switching
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _slideController.dispose(); // Dispose the slide controller
    _feetController.dispose();
    _inchesController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Route _createCustomRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.easeInOut;

        var opacityTween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var scaleTween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return ScaleTransition(
          scale: animation.drive(scaleTween),
          child: FadeTransition(
            opacity: animation.drive(opacityTween),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildNavigationCard(String title, IconData icon, Widget screen) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact(); // Add haptic feedback on tap
        Navigator.of(context).push(_createCustomRoute(screen));
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Theme.of(context).primaryColor),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI Calculator',style: TextStyle(fontWeight: FontWeight.w600)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Height:',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    _useTextFieldInput
                        ? Expanded(
                      child: TextFormField(
                        controller: _feetController,
                        decoration: const InputDecoration(
                            labelText: 'Feet',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            _selectedFeet =
                                int.tryParse(value) ?? _selectedFeet;
                          });
                        },
                      ),
                    )
                        : Expanded(
                      child: DropdownButton<int>(
                        value: _selectedFeet,
                        onChanged: (value) {
                          setState(() {
                            _selectedFeet = value!;
                          });
                        },
                        items: List.generate(11, (index) => index)
                            .map((feet) => DropdownMenuItem(
                          value: feet,
                          child: Text('$feet feet'),
                        ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _useTextFieldInput
                        ? Expanded(
                      child: TextFormField(
                        controller: _inchesController,
                        decoration: const InputDecoration(
                            labelText: 'Inches',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            _selectedInches =
                                int.tryParse(value) ?? _selectedInches;
                          });
                        },
                      ),
                    )
                        : Expanded(
                      child: DropdownButton<int>(
                        value: _selectedInches,
                        onChanged: (value) {
                          setState(() {
                            _selectedInches = value!;
                          });
                        },
                        items: List.generate(12, (index) => index)
                            .map((inches) => DropdownMenuItem(
                          value: inches,
                          child: Text('$inches inches'),
                        ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Select Weight:',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                _useTextFieldInput
                    ? TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _selectedWeight =
                          int.tryParse(value) ?? _selectedWeight;
                    });
                  },
                )
                    : DropdownButton<int>(
                  value: _selectedWeight,
                  onChanged: (value) {
                    setState(() {
                      _selectedWeight = value!;
                    });
                  },
                  items: List.generate(200, (index) => index + 1)
                      .map((weight) => DropdownMenuItem(
                    value: weight,
                    child: Text('$weight kg'),
                  ))
                      .toList(),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Calculate BMI',
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _calculateBmi();
                    }
                  },
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center, // Ensures items align without extra spacing
                          children: [
                            // Clear All button on the left
                            TextButton(
                              onPressed: _clearInputs,
                              child: const Text(
                                'Clear All',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),

                            // Icon button on the right
                            IconButton(
                              icon: Icon(
                                _useTextFieldInput ? Icons.swap_horiz : Icons.swap_horiz,
                                color: Colors.blue,
                              ),
                              onPressed: _switchInputMethod,
                              tooltip: _useTextFieldInput ? 'Switch to Dropdown' : 'Switch to TextField',
                            ),
                          ],
                        ),

                        // BMI text on the next line, centered horizontally
                        Center(
                          child: Text(
                            _bmi != null ? 'Your BMI: ${_bmi!.toStringAsFixed(2)}' : '',
                            style: TextStyle(
                              fontSize: 24,
                              color: _bmi != null ? _getBmiColor(_bmi!) : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),


                    // Slide down animation for the BMI result
                if (_bmi != null) ...[
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -1), // Start above
                      end: Offset.zero, // End at the original position
                    ).animate(CurvedAnimation(
                      parent: _slideController,
                      curve: Curves.easeInOut,
                    )),
                    child: Column(
                      children: [
                        Text(
                          _getBmiCategory(_bmi!),
                          style: TextStyle(
                              fontSize: 20,
                              color: _getBmiColor(_bmi!),
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
                const Text(
                  'Quick Access:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildNavigationCard('History', Icons.history, const HistoryScreen()),
                    _buildNavigationCard('Tips', Icons.lightbulb, TipsScreen(bmi: _bmi)),
                    _buildNavigationCard('Goals', Icons.check_circle, const GoalScreen()),
                    _buildNavigationCard('Trends', Icons.show_chart, const TrendsScreen()),
                  ],
                ),
              ],
            ),
            ]
          ),
        ),
      ),
      )
    );
  }
}
