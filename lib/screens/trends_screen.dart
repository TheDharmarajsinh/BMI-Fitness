import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  _TrendsScreenState createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Future<List<FlSpot>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _dataFuture = _getBmiTrends();
    _controller.forward();
  }

  Future<List<FlSpot>> _getBmiTrends() async {
    final dbHelper = DatabaseHelper();
    final bmiHistory = await dbHelper.getBmiHistory();

    const maxPoints = 20;
    final start = bmiHistory.length > maxPoints ? bmiHistory.length - maxPoints : 0;
    return List.generate(
      bmiHistory.length - start,
          (index) => FlSpot(index.toDouble(), bmiHistory[start + index].bmi),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('BMI Trends', style: TextStyle(fontWeight: FontWeight.w600)),
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
        child: FutureBuilder<List<FlSpot>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              );
            } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
              return const Center(child: Text('No data available for trends.'));
            } else {
              final data = snapshot.data!;
              return FadeTransition(
                opacity: _fadeAnimation,
                child: _buildTrendsChart(data),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildTrendsChart(List<FlSpot> data) {
    // Calculate intervals
    double yMin = data.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 1;
    double yMax = data.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1;

    // Avoid zero intervals
    double xInterval = (data.length > 5) ? (data.length / 5).floorToDouble() : 1;
    double yInterval = (yMax - yMin) / 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'BMI Trends',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onPanUpdate: (details) {
              HapticFeedback.selectionClick();
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        touchTooltipData: const LineTouchTooltipData(),
                        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                          if (event.isInterestedForInteractions && touchResponse != null) {
                            HapticFeedback.selectionClick();
                          }
                        },
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: yInterval,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: yInterval,
                            getTitlesWidget: (value, _) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                value.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: xInterval,
                            getTitlesWidget: (value, _) => Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                value.toStringAsFixed(0),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                      ),
                      minX: 0,
                      maxX: (data.length - 1).toDouble(),
                      minY: yMin,
                      maxY: yMax,
                      lineBarsData: [
                        LineChartBarData(
                          spots: data,
                          isCurved: true,
                          gradient: const LinearGradient(
                            colors: [Colors.blueAccent, Colors.lightBlue],
                          ),
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.blueAccent.withOpacity(0.3),
                                Colors.lightBlueAccent.withOpacity(0.1),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          dotData: const FlDotData(show: false),
                          preventCurveOverShooting: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
