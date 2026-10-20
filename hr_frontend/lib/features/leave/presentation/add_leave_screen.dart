// Location: lib/features/leave/presentation/add_leave_screen.dart

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/theme/app_theme.dart';
import '../data/leave_api_service.dart';
import '../data/models/leave_model.dart';

class AddLeaveScreen extends StatefulWidget {
  const AddLeaveScreen({super.key});

  @override
  State<AddLeaveScreen> createState() => _AddLeaveScreenState();
}

class _AddLeaveScreenState extends State<AddLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final LeaveApiService _leaveApiService = GetIt.instance<LeaveApiService>();

  String _leaveType = LeaveModel.typeAnnual;
  String _startDate = '';
  String _endDate = '';
  String _reason = '';
  bool _isLoading = false;

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final formatted =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() {
      if (isStart) {
        _startDate = formatted;
      } else {
        _endDate = formatted;
      }
    });
  }

  Future<void> _submitLeave() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    final newLeave = LeaveModel(
      leaveType: _leaveType,
      startDate: _startDate,
      endDate: _endDate,
      reason: _reason,
      status: 'PENDING',
    );

    final result = await _leaveApiService.createLeave(newLeave);

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(failure.message)),
        ]),
        backgroundColor: AppColors.error,
      )),
      (_) => Navigator.pop(context, true),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _leaveType = LeaveModel.typeAnnual;
      _startDate = '';
      _endDate = '';
      _reason = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Leave Request'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset form',
            onPressed: _resetForm,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Leave type
                DropdownButtonFormField<String>(
                  value: _leaveType,
                  decoration: AppTheme.inputDecoration(
                    'Leave Type',
                    icon: Icons.beach_access_rounded,
                  ),
                  items: LeaveModel.leaveTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _leaveType = v!),
                ),
                const SizedBox(height: 16),

                // Start date
                GestureDetector(
                  onTap: () => _pickDate(isStart: true),
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: AppTheme.inputDecoration(
                        _startDate.isEmpty ? 'Start Date' : _startDate,
                        icon: Icons.calendar_today_rounded,
                      ),
                      validator: (_) =>
                          _startDate.isEmpty ? 'Please select start date' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // End date
                GestureDetector(
                  onTap: () => _pickDate(isStart: false),
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: AppTheme.inputDecoration(
                        _endDate.isEmpty ? 'End Date' : _endDate,
                        icon: Icons.calendar_today_rounded,
                      ),
                      validator: (_) =>
                          _endDate.isEmpty ? 'Please select end date' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Reason
                TextFormField(
                  decoration: AppTheme.inputDecoration(
                    'Reason (optional)',
                    icon: Icons.note_rounded,
                  ),
                  maxLines: 3,
                  onSaved: (v) => _reason = v?.trim() ?? '',
                ),
                const SizedBox(height: 32),

                // Submit
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: AppTheme.primaryButtonStyle(),
                    onPressed: _isLoading ? null : _submitLeave,
                    icon: _isLoading
                        ? const SizedBox.shrink()
                        : const Icon(Icons.send_rounded,
                            size: 18, color: Colors.white),
                    label: _isLoading
                        ? AppTheme.loadingIndicator()
                        : const Text('Submit Request'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
