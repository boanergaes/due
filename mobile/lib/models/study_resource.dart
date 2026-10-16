class StudyResource {
  final int id;
  final String title;
  final String fileName;
  final String mimeType;
  final int fileSizeBytes;
  final String formattedSize;
  final bool isImage;
  final bool isPdf;
  final bool isText;
  final bool hasExtractedText;
  final String? extractedText;
  final String? viewUrl;
  final String? downloadUrl;
  final DateTime? createdAt;

  const StudyResource({
    required this.id,
    required this.title,
    required this.fileName,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.formattedSize,
    required this.isImage,
    required this.isPdf,
    required this.isText,
    required this.hasExtractedText,
    this.extractedText,
    this.viewUrl,
    this.downloadUrl,
    this.createdAt,
  });

  factory StudyResource.fromJson(Map<String, dynamic> json) {
    return StudyResource(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      title: json['title']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      mimeType: json['mime_type']?.toString() ?? '',
      fileSizeBytes: json['file_size_bytes'] is int
          ? json['file_size_bytes'] as int
          : int.tryParse(json['file_size_bytes']?.toString() ?? '0') ?? 0,
      formattedSize: json['formatted_size']?.toString() ?? '0 B',
      isImage: json['is_image'] == true,
      isPdf: json['is_pdf'] == true,
      isText: json['is_text'] == true,
      hasExtractedText: json['has_extracted_text'] == true,
      extractedText: json['extracted_text']?.toString(),
      viewUrl: json['view_url']?.toString(),
      downloadUrl: json['download_url']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'file_name': fileName,
        'mime_type': mimeType,
        'file_size_bytes': fileSizeBytes,
        'formatted_size': formattedSize,
        'is_image': isImage,
        'is_pdf': isPdf,
        'is_text': isText,
        'has_extracted_text': hasExtractedText,
        'extracted_text': extractedText,
        'view_url': viewUrl,
        'download_url': downloadUrl,
        'created_at': createdAt?.toIso8601String(),
      };
}
