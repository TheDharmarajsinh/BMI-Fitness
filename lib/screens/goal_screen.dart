import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for HapticFeedback
import '../database/database_helper.dart';
import '../models/bmi_goal.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  _GoalScreenState createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> with SingleTickerProviderStateMixin {
  final _goalController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  BmiGoal? _existingGoal;
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fetchGoal();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _fetchGoal() async {
    final goals = await _dbHelper.getBmiGoals();
    if (goals.isNotEmpty) {
      setState(() {
        _existingGoal = goals.first;
      });
      _controller.forward();
    }
  }

  Future<void> _setGoal() async {
    final goalBmi = double.tryParse(_goalController.text);
    if (goalBmi != null && goalBmi > 0) {
      if (_existingGoal != null) {
        final updatedGoal = BmiGoal(
          id: _existingGoal!.id,
          targetBmi: goalBmi,
          date: DateTime.now().toString(),
        );
        await _dbHelper.updateBmiGoal(updatedGoal);
        ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar('Goal updated successfully!'));
      } else {
        final newGoal = BmiGoal(targetBmi: goalBmi, date: DateTime.now().toString());
        await _dbHelper.insertBmiGoal(newGoal);
        ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar('Goal set successfully!'));
      }
      _goalController.clear();
      setState(() {
        _existingGoal = BmiGoal(targetBmi: goalBmi, date: DateTime.now().toString());
      });
      _controller.forward(from: 0.0); // Reanimate goal card

      // Haptic feedback on goal set/update
      HapticFeedback.lightImpact();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar('Please enter a valid target BMI.', isError: true));
    }
  }

  Future<void> _clearGoals() async {
    final confirm = await _showConfirmationDialog();
    if (confirm == true) {
      await _dbHelper.clearGoals();
      ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar('Goal history cleared!'));
      setState(() {
        _existingGoal = null;
      });
      _controller.reverse(); // Hide the goal card

      // Haptic feedback on goal clearance
      HapticFeedback.lightImpact();
    }
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Goal History'),
          content: const Text('Are you sure you want to clear all goal history?'),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact(); // Feedback on cancel
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact(); // Feedback on clear
                Navigator.of(context).pop(true);
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  SnackBar _buildSnackBar(String message, {bool isError = false}) {
    return SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set BMI Goal', style: TextStyle(fontWeight: FontWeight.w600)),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_existingGoal != null)
              SlideTransition(
                position: _slideAnimation,
                child: Card(
                  elevation: 8,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Current Goal:',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${_existingGoal!.targetBmi}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _clearGoals,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Remove Goal'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _goalController,
              decoration: const InputDecoration(
                labelText: 'Target BMI',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                prefixIcon: Icon(Icons.trending_up),
              ),
              keyboardType: TextInputType.number,
              onTap: () {
                // Haptic feedback when the TextField is tapped
                HapticFeedback.lightImpact();
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _setGoal,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(_existingGoal != null ? 'Update Goal' : 'Set Goal'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    _controller.dispose();
    super.dispose();
  }
}
