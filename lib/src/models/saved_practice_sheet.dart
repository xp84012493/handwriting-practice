/// A locally saved practice sheet (characters only; strokes rebuilt from dictionary).
class SavedPracticeSheet {
  const SavedPracticeSheet({
    required this.id,
    required this.characters,
    required this.createdAtMs,
  });

  final String id;
  final String characters;
  final int createdAtMs;

  DateTime get createdAt =>
      DateTime.fromMillisecondsSinceEpoch(createdAtMs, isUtc: false);

  int get characterCount => characters.runes.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'characters': characters,
        'createdAtMs': createdAtMs,
      };

  factory SavedPracticeSheet.fromJson(Map<String, dynamic> json) {
    return SavedPracticeSheet(
      id: json['id'] as String,
      characters: json['characters'] as String,
      createdAtMs: json['createdAtMs'] as int,
    );
  }

  factory SavedPracticeSheet.create(String characters) {
    final now = DateTime.now();
    return SavedPracticeSheet(
      id: now.microsecondsSinceEpoch.toString(),
      characters: characters,
      createdAtMs: now.millisecondsSinceEpoch,
    );
  }
}
