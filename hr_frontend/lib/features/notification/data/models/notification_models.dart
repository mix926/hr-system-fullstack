// lib/features/notification/data/models/notification_models.dart

class AppNotification {
  final String? id;
  final String userId;
  final String notificationType;
  final String title;
  final String message;
  final String? link;
  final bool isRead;
  final String? readAt;
  final String? createdAt;

  AppNotification({
    this.id,
    required this.userId,
    required this.notificationType,
    required this.title,
    required this.message,
    this.link,
    this.isRead = false,
    this.readAt,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id:               j['id']?.toString(),
    userId:           j['user_id']?.toString() ?? '',
    notificationType: j['notification_type']?.toString() ?? 'GENERAL',
    title:            j['title']?.toString() ?? '',
    message:          j['message']?.toString() ?? '',
    link:             j['link']?.toString(),
    isRead:           j['is_read'] as bool? ?? false,
    readAt:           j['read_at']?.toString(),
    createdAt:        j['created_at']?.toString(),
  );
}

class Announcement {
  final String? id;
  final String title;
  final String content;
  final String? targetRole;
  final String? targetDepartmentId;
  final bool isPinned;
  final bool isActive;
  final String? publishDate;
  final String? expiryDate;
  final String? createdBy;
  final String? createdAt;

  Announcement({
    this.id,
    required this.title,
    required this.content,
    this.targetRole,
    this.targetDepartmentId,
    this.isPinned = false,
    this.isActive = true,
    this.publishDate,
    this.expiryDate,
    this.createdBy,
    this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
    id:                 j['id']?.toString(),
    title:              j['title']?.toString() ?? '',
    content:            j['content']?.toString() ?? '',
    targetRole:         j['target_role']?.toString(),
    targetDepartmentId: j['target_department_id']?.toString(),
    isPinned:           j['is_pinned'] as bool? ?? false,
    isActive:           j['is_active'] as bool? ?? true,
    publishDate:        j['publish_date']?.toString(),
    expiryDate:         j['expiry_date']?.toString(),
    createdBy:          j['created_by']?.toString(),
    createdAt:          j['created_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'title':   title,
    'content': content,
    'is_pinned': isPinned,
    if (targetRole         != null) 'target_role':          targetRole,
    if (targetDepartmentId != null) 'target_department_id': targetDepartmentId,
    if (publishDate        != null) 'publish_date':         publishDate,
    if (expiryDate         != null) 'expiry_date':          expiryDate,
  };
}
