// lib/features/performance/presentation/performance_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../employee/data/employee_api_service.dart';
import '../../employee/data/models/employee_model.dart';
import '../data/models/performance_model.dart';
import '../data/performance_api_service.dart';
import 'bloc/performance_bloc.dart';
import 'bloc/performance_event.dart';
import 'bloc/performance_state.dart';

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PerformanceBloc(GetIt.instance<PerformanceApiService>())
            ..add(LoadPerformanceReviewsEvent()),
      child: const _PerformanceView(),
    );
  }
}

class _PerformanceView extends StatefulWidget {
  const _PerformanceView();

  @override
  State<_PerformanceView> createState() => _PerformanceViewState();
}

class _PerformanceViewState extends State<_PerformanceView> {
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userRole = prefs.getString('role') ?? 'STAFF';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Performance Reviews'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: BlocConsumer<PerformanceBloc, PerformanceState>(
        listener: (context, state) {
          if (state is PerformanceOperationSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(state.message)),
              ]),
              backgroundColor: AppColors.success,
            ));
          }
          if (state is PerformanceErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(children: [
                const Icon(Icons.error_outline,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(state.message)),
              ]),
              backgroundColor: AppColors.error,
            ));
          }
        },
        builder: (context, state) {
          if (state is PerformanceLoadingState ||
              state is PerformanceInitialState) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state is PerformanceErrorState) {
            return _buildError(context, state.message);
          }
          if (state is PerformanceLoadedState) {
            if (state.reviews.isEmpty) {
              return _buildEmpty();
            }
            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<PerformanceBloc>()
                    .add(LoadPerformanceReviewsEvent());
              },
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: state.reviews.length,
                itemBuilder: (context, i) =>
                    _buildReviewCard(context, state.reviews[i]),
              ),
            );
          }
          // After operation success, show the loaded list if available
          return _buildEmpty();
        },
      ),
      floatingActionButton: _userRole == 'ADMIN' || _userRole == 'MANAGER'
          ? FloatingActionButton.extended(
              heroTag: 'add_review',
              onPressed: () => _showCreateDialog(context),
              backgroundColor: AppColors.primary,
              elevation: 2,
              icon: const Icon(Icons.rate_review_rounded,
                  color: Colors.white),
              label: const Text('New Review',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  // ── Review Card ───────────────────────────────────────────────
  Widget _buildReviewCard(BuildContext context, PerformanceReview review) {
    final ratingColor = _ratingColor(review.rating);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration(radius: 14),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            // Rating badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ratingColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${review.rating}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ratingColor,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < review.rating ? Icons.star : Icons.star_border,
                        size: 6,
                        color: ratingColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.reviewPeriod,
                      style: AppTextStyles.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    _statusLabel(review.status),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _statusColor(review.status),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          if (review.strengths != null &&
              review.strengths!.isNotEmpty) ...[
            _sectionRow(Icons.check_circle_outline, 'Strengths',
                review.strengths!, AppColors.success),
          ],
          if (review.areasForImprovement != null &&
              review.areasForImprovement!.isNotEmpty) ...[
            _sectionRow(Icons.trending_up_rounded, 'Areas for Improvement',
                review.areasForImprovement!, AppColors.warning),
          ],
          if (review.goals != null && review.goals!.isNotEmpty) ...[
            _sectionRow(Icons.flag_outlined, 'Goals', review.goals!,
                AppColors.primary),
          ],
          if (review.comments != null &&
              review.comments!.isNotEmpty) ...[
            _sectionRow(Icons.comment_outlined, 'Comments',
                review.comments!, AppColors.textSecondary),
          ],
          if (_userRole == 'ADMIN') ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _confirmDelete(context, review.id ?? ''),
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppColors.error),
                label: const Text('Delete',
                    style: TextStyle(color: AppColors.error)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionRow(
      IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.labelBold.copyWith(color: color)),
          ]),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  // ── Create Review Dialog ─────────────────────────────────────
  void _showCreateDialog(BuildContext context) async {
    final bloc = context.read<PerformanceBloc>();
    List<Employee> employees = [];

    // Fetch employees for the dropdown
    final empService = GetIt.instance<EmployeeApiService>();
    final result = await empService.getEmployees();
    result.fold(
      (_) => employees = [],
      (emps) => employees = emps,
    );

    if (!mounted) return;

    if (employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No employees found to review'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }

    Employee? selectedEmployee;
    final periodController = TextEditingController();
    final strengthsController = TextEditingController();
    final improvementsController = TextEditingController();
    final goalsController = TextEditingController();
    final commentsController = TextEditingController();
    int rating = 3;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('New Performance Review',
              style: AppTextStyles.titleLarge),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Employee dropdown
                DropdownButtonFormField<Employee>(
                  decoration: AppTheme.inputDecoration('Select Employee',
                      icon: Icons.person_outline_rounded),
                  items: employees
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.fullName,
                                style: AppTextStyles.bodyMedium),
                          ))
                      .toList(),
                  onChanged: (emp) =>
                      setState(() => selectedEmployee = emp),
                ),
                const SizedBox(height: 12),

                // Review period
                TextField(
                  controller: periodController,
                  decoration: AppTheme.inputDecoration('Review Period',
                      icon: Icons.calendar_today_outlined,
                      suffix: Text('e.g. 2025-Q3',
                          style: AppTextStyles.bodySmall)),
                ),
                const SizedBox(height: 12),

                // Rating
                Row(
                  children: [
                    Text('Rating', style: AppTextStyles.bodyMedium),
                    const SizedBox(width: 12),
                    ...List.generate(5, (i) {
                      return IconButton(
                        icon: Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          color: AppColors.warning,
                          size: 28,
                        ),
                        onPressed: () => setState(() => rating = i + 1),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 8),

                // Strengths
                TextField(
                  controller: strengthsController,
                  maxLines: 2,
                  decoration: AppTheme.inputDecoration('Strengths',
                      icon: Icons.check_circle_outline),
                ),
                const SizedBox(height: 12),

                // Areas for improvement
                TextField(
                  controller: improvementsController,
                  maxLines: 2,
                  decoration: AppTheme.inputDecoration(
                      'Areas for Improvement',
                      icon: Icons.trending_up_rounded),
                ),
                const SizedBox(height: 12),

                // Goals
                TextField(
                  controller: goalsController,
                  maxLines: 2,
                  decoration: AppTheme.inputDecoration('Goals',
                      icon: Icons.flag_outlined),
                ),
                const SizedBox(height: 12),

                // Comments
                TextField(
                  controller: commentsController,
                  maxLines: 2,
                  decoration: AppTheme.inputDecoration('Comments',
                      icon: Icons.comment_outlined),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: AppTheme.primaryButtonStyle(radius: 10),
              onPressed: () {
                if (selectedEmployee == null ||
                    periodController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Please select an employee and period'),
                    backgroundColor: AppColors.warning,
                  ));
                  return;
                }
                final review = PerformanceReview(
                  employeeId: selectedEmployee!.id,
                  reviewPeriod: periodController.text.trim(),
                  rating: rating,
                  strengths: strengthsController.text.trim().isEmpty
                      ? null
                      : strengthsController.text.trim(),
                  areasForImprovement:
                      improvementsController.text.trim().isEmpty
                          ? null
                          : improvementsController.text.trim(),
                  goals: goalsController.text.trim().isEmpty
                      ? null
                      : goalsController.text.trim(),
                  comments: commentsController.text.trim().isEmpty
                      ? null
                      : commentsController.text.trim(),
                  status: 'SUBMITTED',
                );
                bloc.add(CreatePerformanceReviewEvent(review));
                Navigator.pop(ctx);
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete Confirmation ──────────────────────────────────────
  void _confirmDelete(BuildContext context, String reviewId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
              color: AppColors.errorLight, shape: BoxShape.circle),
          child: const Icon(Icons.delete_forever_rounded,
              color: AppColors.error, size: 28),
        ),
        title:
            const Text('Delete Review', style: AppTextStyles.titleLarge),
        content: Text(
          'This action cannot be undone. The performance review will be permanently deleted.',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: AppTheme.dangerButtonStyle(),
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<PerformanceBloc>()
                  .add(DeletePerformanceReviewEvent(reviewId));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  Color _ratingColor(int rating) {
    if (rating >= 4) return AppColors.success;
    if (rating == 3) return AppColors.warning;
    return AppColors.error;
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return 'Draft';
      case 'ACKNOWLEDGED':
        return 'Acknowledged';
      default:
        return 'Submitted';
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return AppColors.textHint;
      case 'ACKNOWLEDGED':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.rate_review_outlined,
              size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text('No performance reviews yet',
              style: AppTextStyles.bodyMedium),
          if (_userRole == 'ADMIN' || _userRole == 'MANAGER') ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: AppTheme.primaryButtonStyle(),
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create First Review'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                  color: AppColors.errorLight, shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text(message,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: AppTheme.primaryButtonStyle(),
              onPressed: () {
                context
                    .read<PerformanceBloc>()
                    .add(LoadPerformanceReviewsEvent());
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
