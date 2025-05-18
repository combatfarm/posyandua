import 'package:flutter/material.dart';

class GrowthData {
  final int month;
  final double height;
  final double weight;

  GrowthData({
    required this.month,
    required this.height,
    required this.weight,
  });

  factory GrowthData.fromMap(Map<String, dynamic> map) {
    return GrowthData(
      month: map['month'] as int,
      height: map['height'] as double,
      weight: map['weight'] as double,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'height': height,
      'weight': weight,
    };
  }
}

class Milestone {
  final String age;
  final bool achieved;
  final String title;
  final String description;
  final IconData icon;

  Milestone({
    required this.age,
    required this.achieved,
    required this.title,
    required this.description,
    required this.icon,
  });

  factory Milestone.fromMap(Map<String, dynamic> map) {
    return Milestone(
      age: map['age'] as String,
      achieved: map['achieved'] as bool,
      title: map['title'] as String,
      description: map['description'] as String,
      icon: map['icon'] as IconData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'age': age,
      'achieved': achieved,
      'title': title,
      'description': description,
      'icon': icon,
    };
  }
}

class Note {
  final String date;
  final String title;
  final String content;
  final Color color;

  Note({
    required this.date,
    required this.title,
    required this.content,
    required this.color,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      date: map['date'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      color: map['color'] as Color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'title': title,
      'content': content,
      'color': color,
    };
  }
}
