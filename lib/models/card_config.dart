import 'text_position.dart';

class TextPositions {
  // Header positions
  final TextPosition toRadioCallsign;  // Contact callsign in "To Radio:" box

  // Footer QSO table positions (inside the table cells)
  final TextPosition date;
  final TextPosition time;
  final TextPosition frequency;
  final TextPosition band;
  final TextPosition mode;
  final TextPosition rstSent;
  final TextPosition rstRcvd;
  final TextPosition twoWay;

  // Footer additional fields
  final TextPosition power;
  final TextPosition remarks;

  const TextPositions({
    required this.toRadioCallsign,
    required this.date,
    required this.time,
    required this.frequency,
    required this.band,
    required this.mode,
    required this.rstSent,
    required this.rstRcvd,
    required this.twoWay,
    required this.power,
    required this.remarks,
  });

  factory TextPositions.defaultPositions() {
    // Layout constants from template_generator (grid-based QSO layout):
    // Card: 4961 x 3189
    // QSO box: rightZoneStart = 4961 * 0.42 = 2083.62
    // boxHeight = 1050, boxTop = 3189 - 1050 - 100 = 2039
    // headerHeight = 65, padding = 40

    const cardWidth = 4961.0;
    const rightZoneStart = cardWidth * 0.42;  // 2083.62
    const qsoBoxWidth = cardWidth - rightZoneStart - 80;  // 2797.38
    const boxTop = 3189.0 - 950.0 - 100.0;  // 2139 (with larger signature)
    const headerHeight = 65.0;
    const padding = 40.0;
    const gridTop = boxTop + headerHeight + 25;  // 2229 (compact vertical spacing)
    const gridLeft = rightZoneStart + padding + 10;  // 2133.62 (centered with margin)
    const gridWidth = qsoBoxWidth - padding * 2 - 20;  // 2697.38 (side margin)
    const colWidth = gridWidth * 0.25;  // 679.35
    const dataRowHeight = 110.0;

    // TO RADIO: value box starts at gridLeft + 480
    const toRadioX = gridLeft + 480 + (gridWidth - 500) / 2;  // Center of value box
    const toRadioY = gridTop + 45;  // 2259 - centered in taller box

    // Row 1 (row1Y = gridTop + 120): DATE, TIME, BAND, MODE (adjusted for taller TO RADIO)
    const row1Y = gridTop + 120 + 65;  // 2399 - value area (below label)
    const dateX = gridLeft + colWidth * 0.5;
    const timeX = gridLeft + colWidth * 1.5;
    const bandX = gridLeft + colWidth * 2.5;
    const modeX = gridLeft + colWidth * 3.5;

    // Row 2 (row2Y = row1Y - 65 + dataRowHeight + 65 = row1Y + 110): FREQ, POWER, RST SENT, RST RCVD
    const row2Y = row1Y + dataRowHeight;  // 2399
    const freqX = dateX;
    const powerX = timeX;
    const rstSentX = bandX;
    const rstRcvdX = modeX;

    // Checkboxes (row3Y = row2Y - 65 + dataRowHeight + 15 + 20 = row2Y + 70)
    const row3Y = row2Y + 60;  // 2459 checkbox center

    // Remarks (row4Y = row3Y + 80 = 2539)
    // Remarks box starts at gridLeft + 220, text starts with left padding
    const remarksY = row3Y + 80 + 35;  // 2574 - value area
    const remarksX = gridLeft + 220 + 20;  // Left edge of remarks box + padding

    return const TextPositions(
      toRadioCallsign: TextPosition(x: toRadioX, y: toRadioY),
      date: TextPosition(x: dateX, y: row1Y),
      time: TextPosition(x: timeX, y: row1Y),
      frequency: TextPosition(x: freqX, y: row2Y),
      band: TextPosition(x: bandX, y: row1Y),
      mode: TextPosition(x: modeX, y: row1Y),
      rstSent: TextPosition(x: rstSentX, y: row2Y),
      rstRcvd: TextPosition(x: rstRcvdX, y: row2Y),
      twoWay: TextPosition(x: gridLeft + 20, y: row3Y),
      power: TextPosition(x: powerX, y: row2Y),
      remarks: TextPosition(x: remarksX, y: remarksY),
    );
  }

  factory TextPositions.fromJson(Map<String, dynamic> json) {
    // Handle legacy format (old field names)
    if (json.containsKey('callsign')) {
      // Legacy format - convert to new format with defaults
      return TextPositions.defaultPositions();
    }

    return TextPositions(
      toRadioCallsign: TextPosition.fromJson(json['toRadioCallsign']),
      date: TextPosition.fromJson(json['date']),
      time: TextPosition.fromJson(json['time']),
      frequency: TextPosition.fromJson(json['frequency']),
      band: TextPosition.fromJson(json['band']),
      mode: TextPosition.fromJson(json['mode']),
      rstSent: TextPosition.fromJson(json['rstSent']),
      rstRcvd: TextPosition.fromJson(json['rstRcvd']),
      twoWay: TextPosition.fromJson(json['twoWay']),
      power: TextPosition.fromJson(json['power']),
      remarks: TextPosition.fromJson(json['remarks']),
    );
  }

  Map<String, dynamic> toJson() => {
        'toRadioCallsign': toRadioCallsign.toJson(),
        'date': date.toJson(),
        'time': time.toJson(),
        'frequency': frequency.toJson(),
        'band': band.toJson(),
        'mode': mode.toJson(),
        'rstSent': rstSent.toJson(),
        'rstRcvd': rstRcvd.toJson(),
        'twoWay': twoWay.toJson(),
        'power': power.toJson(),
        'remarks': remarks.toJson(),
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
  final String? logoPath;
  final int callsignColor; // Color value as int (default: dark blue 0xFF1e3a5f)
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Default callsign color (dark blue matching the template)
  static const int defaultCallsignColor = 0xFF1e3a5f;

  CardConfig({
    this.id,
    required this.callsign,
    required this.name,
    required this.qrzLink,
    required this.textPositions,
    OperatorInfo? operatorInfo,
    this.templatePath,
    this.logoPath,
    int? callsignColor,
    DateTime? createdAt,
    this.updatedAt,
  })  : operatorInfo = operatorInfo ?? const OperatorInfo(),
        callsignColor = callsignColor ?? defaultCallsignColor,
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
      logoPath: json['logoPath'] as String?,
      callsignColor: json['callsignColor'] as int?,
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
        'logoPath': logoPath,
        'callsignColor': callsignColor,
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
    String? logoPath,
    int? callsignColor,
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
      logoPath: logoPath ?? this.logoPath,
      callsignColor: callsignColor ?? this.callsignColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
