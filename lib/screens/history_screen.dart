import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for HapticFeedback
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/bmi_record.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<BmiRecord> _history = []; // Store history records

  @override
  void initState() {
    super.initState();
    _fetchHistory(); // Fetch the history when the widget initializes
  }

  Future<void> _fetchHistory() async {
    final dbHelper = DatabaseHelper();
    _history = await dbHelper.getBmiHistory();
    setState(() {}); // Update state to reflect fetched history
  }

  Future<void> _confirmClearHistory() async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All History'),
          content: const Text('Are you sure you want to delete all BMI records?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false); // Return 'false' on cancel
              },
            ),
            TextButton(
              child: const Text('Clear All'),
              onPressed: () {
                Navigator.of(context).pop(true); // Return 'true' on confirm
              },
            ),
          ],
        );
      },
    );

    // If the user confirmed, proceed with clearing the history
    if (result == true) {
      _clearHistory();
    }
  }

  Future<void> _clearHistory() async {
    final dbHelper = DatabaseHelper();
    await dbHelper.clearHistory();

    setState(() {
      _history.clear(); // Clear the local history list
    });

    // Provide haptic feedback for clearing history
    HapticFeedback.lightImpact(); // Light haptic feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('BMI history cleared!'), behavior: SnackBarBehavior.floating),
    );
  }

  void _removeHistoryItem(int index) async {
    final removedItem = _history[index];

    // Check if the record has a non-null id
    if (removedItem.id != null) {
      _history.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
            (context, animation) => _buildItem(removedItem, animation),
      );

      // Call deleteBmiRecord method to delete the item from the database
      final dbHelper = DatabaseHelper();
      await dbHelper.deleteBmiRecord(removedItem.id!); // Use '!' to safely unwrap the id

      // Provide haptic feedback for item removal
      HapticFeedback.lightImpact();

      // Notify user of the removal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed record: ${removedItem.bmi.toStringAsFixed(2)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Handle the case where id is null (if this scenario could ever occur)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete record. ID is missing.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildItem(BmiRecord record, Animation<double> animation) {
    // Convert height from cm to feet and inches
    double heightInFeet = record.height * 0.0328084;
    int feet = heightInFeet.floor();
    int inches = ((heightInFeet - feet) * 12).round();

    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(record.date.toString()));

    return ScaleTransition(
      scale: animation,
      child: FadeTransition(
        opacity: animation,
        child: Hero(
          tag: 'record_${record.id}', // Unique tag for each record
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 14), // Slightly reduce margins
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12), // Reduced padding for a compact design
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BMI: ${record.bmi.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            text: 'Height: ',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                            children: [
                              TextSpan(
                                text: '${record.height} cm ($feet\' $inches")',
                                style: const TextStyle(fontWeight: FontWeight.normal),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            text: 'Weight: ',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                            children: [
                              TextSpan(
                                text: '${record.weight} kg',
                                style: const TextStyle(fontWeight: FontWeight.normal),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            text: 'Date: ',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                            children: [
                              TextSpan(
                                text: formattedDate,
                                style: const TextStyle(fontWeight: FontWeight.normal),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeHistoryItem(_history.indexOf(record)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }



  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI History', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _confirmClearHistory, // Call the confirm clear method
          ),
        ],
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
      body: FutureBuilder<List<BmiRecord>>(
        future: DatabaseHelper().getBmiHistory(), // Fetch history using FutureBuilder
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Loading indicator
          } else if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error fetching history.',
                style: TextStyle(fontSize: 18, color: Colors.redAccent),
              ),
            ); // Error handling
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            _history = snapshot.data!; // Store the fetched history data
            return AnimatedList(
              key: _listKey,
              initialItemCount: _history.length,
              itemBuilder: (context, index, animation) {
                return _buildItem(_history[index], animation);
              },
            );
          } else {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No BMI history available. Start tracking your BMI!',
                  textAlign: TextAlign.center,
                ),
              ),
            ); // No records case
          }
        },
      ),
    );
  }

}
