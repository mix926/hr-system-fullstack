// lib/features/notification/presentation/bloc/notification_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/notification_api_service.dart';
import '../../data/models/notification_models.dart';

// ── Events ────────────────────────────────────────────────────

abstract class NotificationEvent {}
class LoadNotificationsEvent  extends NotificationEvent { final bool unreadOnly; LoadNotificationsEvent({this.unreadOnly = false}); }
class LoadUnreadCountEvent    extends NotificationEvent {}
class MarkReadEvent           extends NotificationEvent { final String id; MarkReadEvent(this.id); }
class MarkAllReadEvent        extends NotificationEvent {}
class DeleteNotificationEvent extends NotificationEvent { final String id; DeleteNotificationEvent(this.id); }
class LoadAnnouncementsEvent  extends NotificationEvent {}
class CreateAnnouncementEvent extends NotificationEvent { final Announcement announcement; CreateAnnouncementEvent(this.announcement); }
class DeleteAnnouncementEvent extends NotificationEvent { final String id; DeleteAnnouncementEvent(this.id); }

// ── States ────────────────────────────────────────────────────

abstract class NotificationState {}
class NotificationInitial extends NotificationState {}
class NotificationLoading extends NotificationState {}

class NotificationsLoaded extends NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  NotificationsLoaded(this.notifications, {this.unreadCount = 0});
}

class AnnouncementsLoaded extends NotificationState {
  final List<Announcement> announcements;
  AnnouncementsLoaded(this.announcements);
}

class NotificationSuccess extends NotificationState { final String message; NotificationSuccess(this.message); }
class NotificationError   extends NotificationState { final String message; NotificationError(this.message); }

// ── BLoC ──────────────────────────────────────────────────────

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationApiService _api;

  NotificationBloc(this._api) : super(NotificationInitial()) {
    on<LoadNotificationsEvent>(_onLoad);
    on<LoadUnreadCountEvent>(_onUnreadCount);
    on<MarkReadEvent>(_onMarkRead);
    on<MarkAllReadEvent>(_onMarkAllRead);
    on<DeleteNotificationEvent>(_onDelete);
    on<LoadAnnouncementsEvent>(_onLoadAnnouncements);
    on<CreateAnnouncementEvent>(_onCreateAnnouncement);
    on<DeleteAnnouncementEvent>(_onDeleteAnnouncement);
  }

  Future<void> _onLoad(LoadNotificationsEvent e, Emitter emit) async {
    emit(NotificationLoading());
    final r = await _api.getNotifications(unreadOnly: e.unreadOnly);
    final countResult = await _api.getUnreadCount();
    final count = countResult.fold((_) => 0, (c) => c);
    r.fold(
      (f) => emit(NotificationError(f.message)),
      (n) => emit(NotificationsLoaded(n, unreadCount: count)),
    );
  }

  Future<void> _onUnreadCount(LoadUnreadCountEvent e, Emitter emit) async {
    final r = await _api.getUnreadCount();
    r.fold((_) => null, (_) => null); // silent — count embedded in NotificationsLoaded
  }

  Future<void> _onMarkRead(MarkReadEvent e, Emitter emit) async {
    await _api.markRead(e.id);
    add(LoadNotificationsEvent());
  }

  Future<void> _onMarkAllRead(MarkAllReadEvent e, Emitter emit) async {
    await _api.markAllRead();
    add(LoadNotificationsEvent());
  }

  Future<void> _onDelete(DeleteNotificationEvent e, Emitter emit) async {
    await _api.deleteNotification(e.id);
    add(LoadNotificationsEvent());
  }

  Future<void> _onLoadAnnouncements(LoadAnnouncementsEvent e, Emitter emit) async {
    emit(NotificationLoading());
    final r = await _api.getAnnouncements();
    r.fold(
      (f) => emit(NotificationError(f.message)),
      (a) => emit(AnnouncementsLoaded(a)),
    );
  }

  Future<void> _onCreateAnnouncement(CreateAnnouncementEvent e, Emitter emit) async {
    emit(NotificationLoading());
    final r = await _api.createAnnouncement(e.announcement);
    r.fold(
      (f) => emit(NotificationError(f.message)),
      (_) => emit(NotificationSuccess('Announcement created')),
    );
  }

  Future<void> _onDeleteAnnouncement(DeleteAnnouncementEvent e, Emitter emit) async {
    await _api.deleteAnnouncement(e.id);
    add(LoadAnnouncementsEvent());
  }
}
