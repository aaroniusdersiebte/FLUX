class WordToken {
  final String word;
  final int orpIndex;

  const WordToken({required this.word, required this.orpIndex});

  /// The part of the word before the ORP character
  String get prefix => word.substring(0, orpIndex);

  /// The ORP character itself (amber)
  String get orpChar => word.isEmpty ? '' : word[orpIndex];

  /// The part of the word after the ORP character
  String get suffix =>
      orpIndex + 1 < word.length ? word.substring(orpIndex + 1) : '';
}
