class Song {
  final String id;
  final String title;
  final String artist;
  final String duration;
  final String thumbnailUrl;
  final String? streamUrl;
  final bool isDownloaded;
  final String? localFilePath;
  final String genre;
  final double popularity;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.duration = '',
    required this.thumbnailUrl,
    this.streamUrl,
    this.isDownloaded = false,
    this.localFilePath,
    this.genre = 'Pop',
    this.popularity = 0.95,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? duration,
    String? thumbnailUrl,
    String? streamUrl,
    bool? isDownloaded,
    String? localFilePath,
    String? genre,
    double? popularity,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localFilePath: localFilePath ?? this.localFilePath,
      genre: genre ?? this.genre,
      popularity: popularity ?? this.popularity,
    );
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown Title',
      artist: json['artist'] as String? ?? 'Unknown Artist',
      duration: json['duration'] as String? ?? '',
      thumbnailUrl: (json['thumbnail'] ?? json['thumbnailUrl']) as String? ?? '',
      streamUrl: json['streamUrl'] as String?,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      localFilePath: json['localFilePath'] as String?,
      genre: json['genre'] as String? ?? 'Pop',
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.95,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'duration': duration,
      'thumbnail': thumbnailUrl,
      'streamUrl': streamUrl,
      'isDownloaded': isDownloaded,
      'localFilePath': localFilePath,
      'genre': genre,
      'popularity': popularity,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
