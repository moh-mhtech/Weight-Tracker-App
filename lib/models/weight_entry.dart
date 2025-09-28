class WeightEntry {
  final int? id;
  final double weight;
  final DateTime date;

  WeightEntry({
    this.id,
    required this.weight,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weight': weight,
      'date': date.millisecondsSinceEpoch,
    };
  }

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'],
      weight: map['weight'].toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
    );
  }

  WeightEntry copyWith({
    int? id,
    double? weight,
    DateTime? date,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      weight: weight ?? this.weight,
      date: date ?? this.date,
    );
  }
}
