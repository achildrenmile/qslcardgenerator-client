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

/// Operator information displayed on the QSL card
class OperatorInfo {
  final String operatorName;
  final String street;
  final String city; // QTH / Location
  final String country;
  final String locator; // Grid square (e.g., JN66)
  final String email;

  const OperatorInfo({
    this.operatorName = '',
    this.street = '',
    this.city = '',
    this.country = '',
    this.locator = '',
    this.email = '',
  });

  factory OperatorInfo.fromJson(Map<String, dynamic> json) {
    return OperatorInfo(
      operatorName: json['operatorName'] as String? ?? '',
      street: json['street'] as String? ?? '',
      city: json['city'] as String? ?? json['qth'] as String? ?? '',
      country: json['country'] as String? ?? '',
      locator: json['locator'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'operatorName': operatorName,
        'street': street,
        'city': city,
        'country': country,
        'locator': locator,
        'email': email,
      };

  OperatorInfo copyWith({
    String? operatorName,
    String? street,
    String? city,
    String? country,
    String? locator,
    String? email,
  }) {
    return OperatorInfo(
      operatorName: operatorName ?? this.operatorName,
      street: street ?? this.street,
      city: city ?? this.city,
      country: country ?? this.country,
      locator: locator ?? this.locator,
      email: email ?? this.email,
    );
  }
}

class CardConfig {
  final int? id;
  final String callsign;
  final String name;
  final String qrzLink;
  final TextPositions textPositions;
  final OperatorInfo operatorInfo;
  final String? templatePath;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CardConfig({
    this.id,
    required this.callsign,
    required this.name,
    required this.qrzLink,
    required this.textPositions,
    OperatorInfo? operatorInfo,
    this.templatePath,
    DateTime? createdAt,
    this.updatedAt,
  })  : operatorInfo = operatorInfo ?? const OperatorInfo(),
        createdAt = createdAt ?? DateTime.now();

  factory CardConfig.fromJson(Map<String, dynamic> json) {
    return CardConfig(
      id: json['id'] as int?,
      callsign: json['callsign'] as String,
      name: json['name'] as String,
      qrzLink: json['qrzLink'] as String,
      textPositions: TextPositions.fromJson(json['textPositions']),
      operatorInfo: json['operatorInfo'] != null
          ? OperatorInfo.fromJson(json['operatorInfo'])
          : const OperatorInfo(),
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
        'operatorInfo': operatorInfo.toJson(),
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
    OperatorInfo? operatorInfo,
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
      operatorInfo: operatorInfo ?? this.operatorInfo,
      templatePath: templatePath ?? this.templatePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
