class QsoData {
  final String contactCallsign;
  final DateTime utcDateTime;
  final String frequency;
  final String mode;
  final String rst;
  final String additionalLine1;
  final String additionalLine2;

  const QsoData({
    required this.contactCallsign,
    required this.utcDateTime,
    required this.frequency,
    required this.mode,
    required this.rst,
    this.additionalLine1 = '',
    this.additionalLine2 = '',
  });

  factory QsoData.empty() {
    return QsoData(
      contactCallsign: '',
      utcDateTime: DateTime.now().toUtc(),
      frequency: '',
      mode: '',
      rst: '',
      additionalLine1: 'Thanks for the QSO',
      additionalLine2: 'Best regards',
    );
  }

  String get formattedDateTime {
    final d = utcDateTime;
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  QsoData copyWith({
    String? contactCallsign,
    DateTime? utcDateTime,
    String? frequency,
    String? mode,
    String? rst,
    String? additionalLine1,
    String? additionalLine2,
  }) {
    return QsoData(
      contactCallsign: contactCallsign ?? this.contactCallsign,
      utcDateTime: utcDateTime ?? this.utcDateTime,
      frequency: frequency ?? this.frequency,
      mode: mode ?? this.mode,
      rst: rst ?? this.rst,
      additionalLine1: additionalLine1 ?? this.additionalLine1,
      additionalLine2: additionalLine2 ?? this.additionalLine2,
    );
  }
}
