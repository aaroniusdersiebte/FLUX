class BookChapter {
  final String name;
  final int wordIndex;

  const BookChapter({required this.name, required this.wordIndex});

  Map<String, dynamic> toJson() => {'name': name, 'wordIndex': wordIndex};

  factory BookChapter.fromJson(Map<String, dynamic> json) => BookChapter(
        name: json['name'] as String,
        wordIndex: json['wordIndex'] as int,
      );
}

class Book {
  final String id;
  final String title;
  final String author;
  final String filePath;
  final String format; // 'epub' | 'txt' | 'pdf'
  final int totalWords;
  final int wordIndex;
  final DateTime importedAt;
  final List<BookChapter> chapters;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.filePath,
    required this.format,
    required this.totalWords,
    this.wordIndex = 0,
    required this.importedAt,
    this.chapters = const [],
  });

  double get progress =>
      totalWords > 0 ? wordIndex / totalWords : 0.0;

  Book copyWith({
    String? title,
    String? author,
    int? wordIndex,
    int? totalWords,
    List<BookChapter>? chapters,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath,
      format: format,
      totalWords: totalWords ?? this.totalWords,
      wordIndex: wordIndex ?? this.wordIndex,
      importedAt: importedAt,
      chapters: chapters ?? this.chapters,
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
        'chapters': chapters.map((c) => c.toJson()).toList(),
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
        chapters: (json['chapters'] as List<dynamic>? ?? [])
            .map((e) => BookChapter.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
