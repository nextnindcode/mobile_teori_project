import 'package:flutter/material.dart';

import 'shared/json_utils.dart';

class Member {
  final int id;
  final String stageName;
  final String position;
  final String description;
  final String funFact;
  final String? imageUrl;

  const Member({
    required this.id,
    required this.stageName,
    required this.position,
    required this.description,
    required this.funFact,
    required this.imageUrl,
  });

  String get initial =>
      stageName.isEmpty ? '?' : stageName.substring(0, 1).toUpperCase();

  factory Member.fromJson(Map<String, dynamic> json) => Member(
    id: toInt(json['id']),
    stageName: '${json['stage_name'] ?? ''}',
    position: '${json['position'] ?? ''}',
    description: '${json['description'] ?? ''}',
    funFact: '${json['fun_fact'] ?? ''}',
    imageUrl: json['image_url']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'stage_name': stageName,
    'position': position,
    'description': description,
    'fun_fact': funFact,
    'image_url': imageUrl,
  };
}

const _memberColors = <Color>[
  Color(0xFF674188),
  Color(0xFF8E5AA8),
  Color(0xFFB07CC6),
  Color(0xFF3F51B5),
  Color(0xFF00897B),
  Color(0xFF43A047),
  Color(0xFFEF6C00),
  Color(0xFFD84315),
  Color(0xFFC2185B),
  Color(0xFF5D4037),
  Color(0xFF0277BD),
  Color(0xFF6A1B9A),
  Color(0xFF455A64),
];

Color memberColor(int id) => _memberColors[id.abs() % _memberColors.length];
