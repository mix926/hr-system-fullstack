// Location: lib/features/leave/presentation/add_leave_screen.dart

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/utils/constants.dart';
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

  String _leaveType = 'Annual Leave';
  String _startDate = '';
  String _endDate = '';
  String _reason = '';
  bool _isLoading = false;

  final List<String> _leaveTypes = ['Annual Leave', 'Sick Leave', 'Unpaid Leave', 'Maternity Leave'];

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
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: AppConstants.errorColor),
        );
      },
      (success) {
        Navigator.pop(context, true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('New Leave Request', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _leaveType,
                decoration: _inputDecoration('Leave Type', Icons.work_outline),
                items: _leaveTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) => setState(() => _leaveType = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: _inputDecoration('Start Date (YYYY-MM-DD)', Icons.calendar_today_rounded),
                validator: (v) => v == null || v.isEmpty ? 'Please enter start date' : null,
                onSaved: (v) => _startDate = v!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: _inputDecoration('End Date (YYYY-MM-DD)', Icons.calendar_today_rounded),
                validator: (v) => v == null || v.isEmpty ? 'Please enter end date' : null,
                onSaved: (v) => _endDate = v!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: _inputDecoration('Reason', Icons.note_rounded),
                maxLines: 3,
                onSaved: (v) => _reason = v?.trim() ?? '',
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitLeave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }
}