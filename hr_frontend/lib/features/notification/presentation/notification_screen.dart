// lib/features/notification/presentation/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import 'bloc/notification_bloc.dart';
import '../data/models/notification_models.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationBloc>()..add(LoadNotificationsEvent()),
      child: const _NotificationView(),
    );
  }
}

class _NotificationView extends StatefulWidget {
  const _NotificationView();
  @override
  State<_NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<_NotificationView>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (_tabs.index == 1) {
        context.read<NotificationBloc>().add(LoadAnnouncementsEvent());
      } else {
        context.read<NotificationBloc>().add(LoadNotificationsEvent());
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (_, state) {
            int badge = 0;
            if (state is NotificationsLoaded) badge = state.unreadCount;
            return Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Notifications'),
              if (badge > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red, borderRadius: BorderRadius.circular(10)),
                  child: Text('$badge',
                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ],
            ]);
          },
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (ctx, state) {
              if (state is NotificationsLoaded && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () => ctx.read<NotificationBloc>().add(MarkAllReadEvent()),
                  child: const Text('Mark all read',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                );
              }
              return const SizedBox();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.notifications_outlined), text: 'Inbox'),
            Tab(icon: Icon(Icons.campaign_outlined), text: 'Announcements'),
          ],
        ),
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (ctx, state) {
          if (state is NotificationSuccess) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green));
          }
          if (state is NotificationError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (ctx, state) {
          return TabBarView(
            controller: _tabs,
            children: [
              _InboxTab(state: state),
              _AnnouncementsTab(state: state),
            ],
          );
        },
      ),
      floatingActionButton: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (ctx, state) {
          if (_tabs.index == 1) {
            return FloatingActionButton.extended(
              onPressed: () => _showCreateAnnouncementDialog(ctx),
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Announce', style: TextStyle(color: Colors.white)),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showCreateAnnouncementDialog(BuildContext context) {
    final titleC   = TextEditingController();
    final contentC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Announcement'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: titleC,
                decoration: const InputDecoration(labelText: 'Title *')),
            const SizedBox(height: 12),
            TextField(controller: contentC, maxLines: 4,
                decoration: const InputDecoration(labelText: 'Content *')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () {
              if (titleC.text.isEmpty || contentC.text.isEmpty) return;
              context.read<NotificationBloc>().add(CreateAnnouncementEvent(
                Announcement(title: titleC.text, content: contentC.text),
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Post', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Inbox Tab ─────────────────────────────────────────────────

class _InboxTab extends StatelessWidget {
  final NotificationState state;
  const _InboxTab({required this.state});

  static const _typeIcons = {
    'LEAVE_REQUEST': (Icons.beach_access, Colors.orange),
    'LEAVE_APPROVED': (Icons.check_circle, Colors.green),
    'LEAVE_REJECTED': (Icons.cancel, Colors.red),
    'PAYSLIP_GENERATED': (Icons.receipt_long, Colors.blue),
    'DOCUMENT_EXPIRY': (Icons.warning_amber, Colors.amber),
    'PERFORMANCE_REVIEW': (Icons.star, Colors.purple),
    'INTERVIEW_SCHEDULED': (Icons.video_call, Colors.teal),
    'OFFER_STATUS': (Icons.local_offer, Colors.indigo),
    'ANNOUNCEMENT': (Icons.campaign, Colors.pink),
    'GENERAL': (Icons.notifications, Colors.grey),
  };

  @override
  Widget build(BuildContext context) {
    if (state is NotificationLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is NotificationsLoaded) {
      final notifs = (state as NotificationsLoaded).notifications;
      if (notifs.isEmpty) {
        return const _EmptyState(icon: Icons.notifications_off_outlined,
            label: 'You\'re all caught up!');
      }
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: notifs.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (ctx, i) => _NotificationTile(
          notification: notifs[i],
          typeConfig: _typeIcons[notifs[i].notificationType] ??
              _typeIcons['GENERAL']!,
          onTap: () {
            if (!notifs[i].isRead && notifs[i].id != null) {
              ctx.read<NotificationBloc>().add(MarkReadEvent(notifs[i].id!));
            }
          },
          onDelete: () {
            if (notifs[i].id != null) {
              ctx.read<NotificationBloc>()
                  .add(DeleteNotificationEvent(notifs[i].id!));
            }
          },
        ),
      );
    }
    return const SizedBox();
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final (IconData, Color) typeConfig;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _NotificationTile({
    required this.notification,
    required this.typeConfig,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = typeConfig;
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: isUnread ? color.withOpacity(0.04) : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(notification.title,
                    style: TextStyle(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal))),
                if (isUnread)
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              ]),
              const SizedBox(height: 3),
              Text(notification.message,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              if (notification.createdAt != null) ...[
                const SizedBox(height: 4),
                Text(_formatDate(notification.createdAt!),
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ])),
          ]),
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw.substring(0, min(10, raw.length));
    }
  }

  int min(int a, int b) => a < b ? a : b;
}

// ── Announcements Tab ─────────────────────────────────────────

class _AnnouncementsTab extends StatelessWidget {
  final NotificationState state;
  const _AnnouncementsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state is NotificationLoading) return const Center(child: CircularProgressIndicator());
    if (state is AnnouncementsLoaded) {
      final list = (state as AnnouncementsLoaded).announcements;
      if (list.isEmpty) {
        return const _EmptyState(icon: Icons.campaign_outlined, label: 'No announcements');
      }
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => _AnnouncementCard(
          announcement: list[i],
          onDelete: list[i].id != null
              ? () => ctx.read<NotificationBloc>().add(DeleteAnnouncementEvent(list[i].id!))
              : null,
        ),
      );
    }
    return const SizedBox();
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback? onDelete;
  const _AnnouncementCard({required this.announcement, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: announcement.isPinned ? 3 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (announcement.isPinned) ...[
              const Icon(Icons.push_pin, size: 16, color: Colors.orange),
              const SizedBox(width: 6),
            ],
            Expanded(child: Text(announcement.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 18),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ]),
          const SizedBox(height: 8),
          Text(announcement.content,
              style: const TextStyle(color: Colors.black87, height: 1.4)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            if (announcement.targetRole != null)
              _Tag(announcement.targetRole!, Colors.blue),
            if (announcement.createdAt != null)
              _Tag(_shortDate(announcement.createdAt!), Colors.grey),
          ]),
        ]),
      ),
    );
  }

  String _shortDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw.substring(0, raw.length > 10 ? 10 : raw.length);
    }
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
    child: Text(label, style: TextStyle(color: color, fontSize: 11)),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyState({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      Text(label, style: TextStyle(color: Colors.grey.shade500)),
    ]),
  );
}
