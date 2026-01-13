import 'text_position.dart';

class TextPositions {
  final TextPosition callsign;
  final TextPosition utcDateTime;
  final TextPosition frequency;
  final TextPosition mode;
  final TextPosition rst;
  final TextPosition additional;

  const TextPositions({
    required this.callsign,
    required this.utcDateTime,
    required this.frequency,
    required this.mode,
    required this.rst,
    required this.additional,
  });

  factory TextPositions.defaultPositions() {
    return const TextPositions(
      callsign: TextPosition(x: 3368, y: 2026),
      utcDateTime: TextPosition(x: 2623, y: 2499),
      frequency: TextPosition(x: 3398, y: 2499),
      mode: TextPosition(x: 3906, y: 2499),
      rst: TextPosition(x: 4353, y: 2499),
      additional: TextPosition(x: 2027, y: 2760),
    );
  }

  factory TextPositions.fromJson(Map<String, dynamic> json) {
    return TextPositions(
      callsign: TextPosition.fromJson(json['callsign']),
      utcDateTime: TextPosition.fromJson(json['utcDateTime']),
      frequency: TextPosition.fromJson(json['frequency']),
      mode: TextPosition.fromJson(json['mode']),
      rst: TextPosition.fromJson(json['rst']),
      additional: TextPosition.fromJson(json['additional']),
    );
  }

  Map<String, dynamic> toJson() => {
        'callsign': callsign.toJson(),
        'utcDateTime': utcDateTime.toJson(),
        'frequency': frequency.toJson(),
        'mode': mode.toJson(),
        'rst': rst.toJson(),
        'additional': additional.toJson(),
      };
}

class CardConfig {
  final int? id;
  final String callsign;
  final String name;
  final String qrzLink;
  final TextPositions textPositions;
  final String? templatePath;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CardConfig({
    this.id,
    required this.callsign,
    required this.name,
    required this.qrzLink,
    required this.textPositions,
    this.templatePath,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CardConfig.fromJson(Map<String, dynamic> json) {
    return CardConfig(
      id: json['id'] as int?,
      callsign: json['callsign'] as String,
      name: json['name'] as String,
      qrzLink: json['qrzLink'] as String,
      textPositions: TextPositions.fromJson(json['textPositions']),
      templatePath: json['templatePath'] as String?,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'callsign': callsign,
        'name': name,
        'qrzLink': qrzLink,
        'textPositions': textPositions.toJson(),
        'templatePath': templatePath,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  CardConfig copyWith({
    int? id,
    String? callsign,
    String? name,
    String? qrzLink,
    TextPositions? textPositions,
    String? templatePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CardConfig(
      id: id ?? this.id,
      callsign: callsign ?? this.callsign,
      name: name ?? this.name,
      qrzLink: qrzLink ?? this.qrzLink,
      textPositions: textPositions ?? this.textPositions,
      templatePath: templatePath ?? this.templatePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
