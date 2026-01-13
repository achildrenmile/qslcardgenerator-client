class TextPosition {
  final double x;
  final double y;

  const TextPosition({required this.x, required this.y});

  factory TextPosition.fromJson(Map<String, dynamic> json) {
    return TextPosition(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  TextPosition copyWith({double? x, double? y}) {
    return TextPosition(x: x ?? this.x, y: y ?? this.y);
  }
}
