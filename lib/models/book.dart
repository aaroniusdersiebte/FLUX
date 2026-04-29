class Book {
  final String id;
  final String title;
  final String author;
  final String filePath;
  final String format; // 'epub' | 'txt'
  final int totalWords;
  final int wordIndex;
  final DateTime importedAt;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.filePath,
    required this.format,
    required this.totalWords,
    this.wordIndex = 0,
    required this.importedAt,
  });

  double get progress =>
      totalWords > 0 ? wordIndex / totalWords : 0.0;

  Book copyWith({
    int? wordIndex,
    int? totalWords,
  }) {
    return Book(
      id: id,
      title: title,
      author: author,
      filePath: filePath,
      format: format,
      totalWords: totalWords ?? this.totalWords,
      wordIndex: wordIndex ?? this.wordIndex,
      importedAt: importedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'filePath': filePath,
        'format': format,
        'totalWords': totalWords,
        'wordIndex': wordIndex,
        'importedAt': importedAt.toIso8601String(),
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'] as String,
        title: json['title'] as String,
        author: json['author'] as String,
        filePath: json['filePath'] as String,
        format: json['format'] as String,
        totalWords: json['totalWords'] as int,
        wordIndex: json['wordIndex'] as int? ?? 0,
        importedAt: DateTime.parse(json['importedAt'] as String),
      );
}
