import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart'; // For HapticFeedback

class TipsScreen extends StatefulWidget {
  final double? bmi;

  const TipsScreen({super.key, this.bmi});

  @override
  _TipsScreenState createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Tips' , style: TextStyle(fontWeight: FontWeight.w600)),
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
      body: Scrollbar(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: widget.bmi == null ? _buildNoBmiMessage() : _buildTipsContent(widget.bmi!),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoBmiMessage() {
    return const Center(child: Text('Calculate your BMI on the previous screen first.'));
  }

  Widget _buildTipsContent(double bmi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personalized Health Tips:',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _getTipsWidget(bmi),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 10),
        const Text(
          'Nutrition Tips:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildTipCard(0, '1. Stay Hydrated',
            'Drink plenty of water throughout the day to keep your metabolism functioning well.'),
        _buildTipCard(1, '2. Balance Your Plate',
            'Include a variety of food groups in your meals, such as fruits, vegetables, whole grains, and protein.'),
        _buildTipCard(2, '3. Watch Portion Sizes',
            'Be mindful of portion sizes to avoid overeating, even healthy foods.'),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 10),
        const Text(
          'Exercise Tips:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildExerciseTip(
            3,
            '1. Strength Training',
            'Increase muscle mass and metabolism.',
            'https://youtu.be/2tM1LFFxeKg?si=GrXMjj6q4Tr6dvNH'),
        _buildExerciseTip(
            4,
            '2. Cardio',
            'Walking, running, or cycling can help maintain a healthy weight.',
            'https://youtu.be/hmFQqjMF_f0?si=TT_c3Y8Yp15eqdwU'),
        _buildExerciseTip(
            5,
            '3. Yoga',
            'Improve flexibility and reduce stress.',
            'https://youtu.be/_8kV4FHSdNA?si=KSeWidopymiFLV-n'),
        _buildExerciseTip(
            6,
            '4. High-Intensity Interval Training (HIIT)',
            'Burn more calories in less time.',
            'https://youtu.be/dw_4hTK1_ek?si=Ohp2pLVX2DCajXUV'),
        _buildExerciseTip(
            7,
            '5. Regular Walking',
            'Aim for at least 30 minutes of walking daily.',
            'https://youtu.be/QccHnESzyUo?si=SVjUS1RZh-3U8ONu'),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 10),
        const Text(
          'Useful Links:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildLink(8, 'Nutrition Guidelines',
            'https://www.who.int/news-room/fact-sheets/detail/healthy-diet'),
        _buildLink(9, 'Exercise Recommendations',
            'https://www.cdc.gov/physicalactivity/basics/index.htm'),
      ],
    );
  }

  Widget _getTipsWidget(double bmi) {
    String advice = _getAdviceBasedOnBmi(bmi);
    Color color = _getBmiColor(bmi);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        advice,
        style: const TextStyle(fontSize: 18, color: Colors.black87),
      ),
    );
  }

  String _getAdviceBasedOnBmi(double bmi) {
    if (bmi < 18.5) {
      return 'You are underweight. Consider increasing your calorie intake and incorporating strength training exercises.';
    } else if (bmi < 24.9) {
      return 'You have a healthy weight. Maintain a balanced diet and regular exercise to stay fit.';
    } else if (bmi < 29.9) {
      return 'You are overweight. Consider a balanced diet and regular physical activity to help lose weight.';
    } else {
      return 'You are obese. It is recommended to consult a healthcare provider for personalized advice.';
    }
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) {
      return Colors.blue; // Underweight
    } else if (bmi < 24.9) {
      return Colors.green; // Normal
    } else if (bmi < 29.9) {
      return Colors.amber; // Overweight
    } else {
      return Colors.red; // Obese
    }
  }

  Widget _buildTipCard(int index, String title, String description) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.local_dining, size: 30, color: Colors.green),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseTip(int index, String title, String description, String url) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact(); // Haptic feedback on tap
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20.0),
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.fitness_center,
              color: Colors.blue,
              size: 35,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.play_circle_fill, color: Colors.lightBlueAccent, size: 30),
              onPressed: () => launch(url),
              tooltip: 'Watch Video',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLink(int index, String title, String url) {
    return GestureDetector(
      onTap: () => launch(url),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
