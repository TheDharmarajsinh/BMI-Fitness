class BmiRecord {
  final int? id;
  final double bmi;
  final double height;
  final double weight;
  final String date;

  BmiRecord({this.id, required this.bmi, required this.height, required this.weight, required this.date});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bmi': bmi,
      'height': height,
      'weight': weight,
      'date': date,
    };
  }
}
