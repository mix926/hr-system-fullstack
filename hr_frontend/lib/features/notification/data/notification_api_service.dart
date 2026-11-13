// lib/features/notification/data/notification_api_service.dart

import 'package:dio/dio.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/constants.dart';
import 'models/notification_models.dart';

class NotificationApiService {
  final Dio _dio;
  NotificationApiService(this._dio);

  String _detail(DioException e, String fb) {
    final d = e.response?.data;
    if (d is Map<String, dynamic>) return d['detail']?.toString() ?? fb;
    if (d is String && d.isNotEmpty) return d;
    return fb;
  }

  Future<Result<List<AppNotification>>> getNotifications({bool unreadOnly = false}) async {
    try {
      final r = await _dio.get(AppConstants.notificationsEndpoint,
          queryParameters: unreadOnly ? {'unread_only': true} : null);
      return Result.success((r.data as List).map((j) => AppNotification.fromJson(j)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load notifications')));
    }
  }

  Future<Result<int>> getUnreadCount() async {
    try {
      final r = await _dio.get(AppConstants.unreadCountEndpoint);
      return Result.success((r.data['unread_count'] as num).toInt());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to get unread count')));
    }
  }

  Future<Result<AppNotification>> markRead(String id) async {
    try {
      final r = await _dio.patch(AppConstants.notificationReadEndpoint(id));
      return Result.success(AppNotification.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to mark read')));
    }
  }

  Future<Result<void>> markAllRead() async {
    try {
      await _dio.post(AppConstants.markAllReadEndpoint);
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to mark all read')));
    }
  }

  Future<Result<void>> deleteNotification(String id) async {
    try {
      await _dio.delete(AppConstants.notificationDeleteEndpoint(id));
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to delete notification')));
    }
  }

  // ── Announcements ─────────────────────────────────────────────

  Future<Result<List<Announcement>>> getAnnouncements({bool activeOnly = true}) async {
    try {
      final r = await _dio.get(AppConstants.announcementsEndpoint,
          queryParameters: {'active_only': activeOnly});
      return Result.success((r.data as List).map((j) => Announcement.fromJson(j)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load announcements')));
    }
  }

  Future<Result<Announcement>> createAnnouncement(Announcement a) async {
    try {
      final r = await _dio.post(AppConstants.announcementsEndpoint, data: a.toJson());
      return Result.success(Announcement.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to create announcement')));
    }
  }

  Future<Result<void>> deleteAnnouncement(String id) async {
    try {
      await _dio.delete(AppConstants.announcementByIdEndpoint(id));
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to delete announcement')));
    }
  }
}
