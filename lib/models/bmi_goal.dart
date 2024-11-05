class BmiGoal {
  final int? id;
  final double targetBmi;
  final String date;

  BmiGoal({this.id, required this.targetBmi, required this.date});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'targetBmi': targetBmi,
      'date': date,
    };
  }
}
