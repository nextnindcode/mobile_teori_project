import 'package:flutter/material.dart';

import 'shared/json_utils.dart';

class Member {
  final int id;
  final String stageName;
  final String position;
  final String team;
  final String description;
  final String funFact;
  final String? imageUrl;
  final Map<String, dynamic> extraDetails;

  const Member({
    required this.id,
    required this.stageName,
    required this.position,
    required this.team,
    required this.description,
    required this.funFact,
    required this.imageUrl,
    this.extraDetails = const {},
  });

  String get initial =>
      stageName.isEmpty ? '?' : stageName.substring(0, 1).toUpperCase();

  factory Member.fromJson(Map<String, dynamic> json) {
    // Tentukan team default dari position jika team kosong
    String team = '${json['team'] ?? ''}'.trim();
    if (team.isEmpty) {
      final pos = '${json['position'] ?? ''}'.toLowerCase();
      if (pos.contains('vocal') || ['solen', 'lunar', 'astra', 'mira'].contains('${json['stage_name']}'.toLowerCase())) {
        team = 'Vocal Team';
      } else if (pos.contains('rapper') || pos.contains('rap') || ['zephyr', 'atlas', 'lyra'].contains('${json['stage_name']}'.toLowerCase())) {
        team = 'Hip-Hop Team';
      } else {
        team = 'Performance Team';
      }
    }

    return Member(
      id: toInt(json['id']),
      stageName: '${json['stage_name'] ?? ''}',
      position: '${json['position'] ?? ''}',
      team: team,
      description: '${json['description'] ?? ''}',
      funFact: '${json['fun_fact'] ?? ''}',
      imageUrl: json['image_url']?.toString(),
      extraDetails: Map<String, dynamic>.fromEntries(json.entries.where((entry) {
        const known = {'id', 'stage_name', 'position', 'team', 'description', 'fun_fact', 'image_url', 'profile_image_path', 'sort_order', 'created_at', 'updated_at', 'is_active'};
        final key = entry.key.toLowerCase();
        final value = entry.value;
        return !known.contains(key) && !key.contains('image') && !key.endsWith('_path') && value != null && value.toString().trim().isNotEmpty;
      })),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'stage_name': stageName,
    'position': position,
    'team': team,
    'description': description,
    'fun_fact': funFact,
    'image_url': imageUrl,
    ...extraDetails,
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
