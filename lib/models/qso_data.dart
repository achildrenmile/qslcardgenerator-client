class QsoData {
  final String contactCallsign;
  final DateTime utcDateTime;
  final String frequency;
  final String band;
  final String mode;
  final String rstSent;
  final String rstRcvd;
  final String power;
  final bool twoWay;
  final bool pseQsl;
  final bool tnxQsl;
  final String remarks;

  const QsoData({
    required this.contactCallsign,
    required this.utcDateTime,
    required this.frequency,
    this.band = '',
    required this.mode,
    required this.rstSent,
    this.rstRcvd = '',
    this.power = '',
    this.twoWay = true,
    this.pseQsl = false,
    this.tnxQsl = true,
    this.remarks = '',
  });

  factory QsoData.empty() {
    return QsoData(
      contactCallsign: '',
      utcDateTime: DateTime.now().toUtc(),
      frequency: '',
      band: '',
      mode: '',
      rstSent: '59',
      rstRcvd: '',
      power: '',
      twoWay: true,
      pseQsl: false,
      tnxQsl: true,
      remarks: 'Thanks for the QSO! 73',
    );
  }

  String get formattedDate {
    final d = utcDateTime;
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  String get formattedTime {
    final d = utcDateTime;
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDateTime {
    return '$formattedDate $formattedTime';
  }

  QsoData copyWith({
    String? contactCallsign,
    DateTime? utcDateTime,
    String? frequency,
    String? band,
    String? mode,
    String? rstSent,
    String? rstRcvd,
    String? power,
    bool? twoWay,
    bool? pseQsl,
    bool? tnxQsl,
    String? remarks,
  }) {
    return QsoData(
      contactCallsign: contactCallsign ?? this.contactCallsign,
      utcDateTime: utcDateTime ?? this.utcDateTime,
      frequency: frequency ?? this.frequency,
      band: band ?? this.band,
      mode: mode ?? this.mode,
      rstSent: rstSent ?? this.rstSent,
      rstRcvd: rstRcvd ?? this.rstRcvd,
      power: power ?? this.power,
      twoWay: twoWay ?? this.twoWay,
      pseQsl: pseQsl ?? this.pseQsl,
      tnxQsl: tnxQsl ?? this.tnxQsl,
      remarks: remarks ?? this.remarks,
    );
  }
}
