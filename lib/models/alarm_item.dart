import 'package:flutter/material.dart';

class AlarmItem {
  const AlarmItem({
    required this.id,
    required this.hour,
    required this.minute,
    required this.label,
    required this.enabled,
  });

  final int id;
  final int hour;
  final int minute;
  final String label;
  final bool enabled;

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  AlarmItem copyWith({
    int? id,
    int? hour,
    int? minute,
    String? label,
    bool? enabled,
  }) {
    return AlarmItem(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'enabled': enabled,
      };

  factory AlarmItem.fromJson(Map<String, dynamic> json) {
    return AlarmItem(
      id: json['id'] as int,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      label: json['label'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  String formatTime(BuildContext context) {
    return TimeOfDay(hour: hour, minute: minute).format(context);
  }
}
