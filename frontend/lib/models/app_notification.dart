/// Satu notifikasi dalam aplikasi (disimpan di tabel notifications).
class AppNotification {
  final int id;
  final int? requestId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.requestId,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        requestId: requestId,
        title: title,
        message: message,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final read = json['is_read'];
    return AppNotification(
      id: (json['id'] as num).toInt(),
      requestId: json['request_id'] == null
          ? null
          : (json['request_id'] as num).toInt(),
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: read == true || read == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
