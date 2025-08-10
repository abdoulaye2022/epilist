// models/feedback_models.dart
class FeedbackType {
  final String value;
  final String label;
  final String description;
  final String icon;

  const FeedbackType({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
  });

  factory FeedbackType.fromJson(Map<String, dynamic> json) {
    return FeedbackType(
      value: json['value'] ?? '',
      label: json['label'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
      'description': description,
      'icon': icon,
    };
  }

  @override
  String toString() => '$icon $label';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedbackType &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class PriorityLevel {
  final String value;
  final String label;

  const PriorityLevel({required this.value, required this.label});

  factory PriorityLevel.fromJson(Map<String, dynamic> json) {
    return PriorityLevel(
      value: json['value'] ?? '',
      label: json['label'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'value': value, 'label': label};
  }

  @override
  String toString() => label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriorityLevel &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}
