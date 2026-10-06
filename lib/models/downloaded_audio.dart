/// Local metadata for a Quran sura MP3 stored in shared storage (MediaStore).
class DownloadedAudio {
  const DownloadedAudio({
    required this.suraId,
    required this.reciterId,
    required this.reciterName,
    required this.localUri,
    required this.fileSizeBytes,
    required this.downloadedAt,
  });

  /// Sura number (1–114).
  final int suraId;

  /// Reciter this file was downloaded for.
  final int reciterId;

  /// Reciter display name (used for folder + Downloads search).
  final String reciterName;

  /// MediaStore content URI (or path) of the local MP3.
  final String localUri;

  /// File size in bytes.
  final int fileSizeBytes;

  /// When the download finished.
  final DateTime downloadedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'suraId': suraId,
      'reciterId': reciterId,
      'reciterName': reciterName,
      'localUri': localUri,
      'fileSizeBytes': fileSizeBytes,
      'downloadedAt': downloadedAt.toIso8601String(),
    };
  }

  /// Builds from SharedPreferences JSON.
  factory DownloadedAudio.fromJson(Map<String, dynamic> json) {
    return DownloadedAudio(
      suraId: (json['suraId'] as num).toInt(),
      reciterId: (json['reciterId'] as num).toInt(),
      reciterName: (json['reciterName'] as String?) ?? '',
      localUri: json['localUri'] as String,
      fileSizeBytes: (json['fileSizeBytes'] as num).toInt(),
      downloadedAt: DateTime.parse(json['downloadedAt'] as String),
    );
  }

  DownloadedAudio copyWith({
    int? suraId,
    int? reciterId,
    String? reciterName,
    String? localUri,
    int? fileSizeBytes,
    DateTime? downloadedAt,
  }) {
    return DownloadedAudio(
      suraId: suraId ?? this.suraId,
      reciterId: reciterId ?? this.reciterId,
      reciterName: reciterName ?? this.reciterName,
      localUri: localUri ?? this.localUri,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      downloadedAt: downloadedAt ?? this.downloadedAt,
    );
  }
}
