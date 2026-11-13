// lib/features/reports/presentation/reports_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import 'bloc/reports_bloc.dart';
import '../data/reports_api_service.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReportsBloc>(),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatefulWidget {
  const _ReportsView();
  @override
  State<_ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<_ReportsView> {
  int _selectedYear = DateTime.now().year;
  String _attendanceStart = '${DateTime.now().year}-01-01';
  String _attendanceEnd   = DateTime.now().toString().substring(0, 10);
  String _payrollMonth    = DateTime.now().toString().substring(0, 7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<ReportsBloc, ReportsState>(
        listener: (ctx, state) {
          if (state is ReportsError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (ctx, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Headcount ───────────────────────────────────
              _SectionHeader('Headcount'),
              _ReportCard(
                icon: Icons.people,
                color: Colors.blue,
                title: 'Employee Headcount',
                subtitle: 'By department, role & lifecycle status',
                onGenerate: () => ctx.read<ReportsBloc>().add(LoadHeadcountReportEvent()),
                exportUrl: sl<ReportsApiService>().getExportUrl('headcount'),
                isLoading: state is ReportsLoading,
                result: state is ReportLoaded && state.reportType == 'headcount' ? state.data : null,
                builder: _buildHeadcountContent,
              ),
              const SizedBox(height: 12),

              // ── Turnover ─────────────────────────────────────
              _SectionHeader('Turnover'),
              _ReportCard(
                icon: Icons.trending_down,
                color: Colors.orange,
                title: 'Turnover Rate',
                subtitle: 'Hires vs exits — year $_selectedYear',
                headerAction: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.arrow_left),
                      onPressed: () => setState(() => _selectedYear--)),
                  Text('$_selectedYear', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.arrow_right),
                      onPressed: () => setState(() => _selectedYear++)),
                ]),
                onGenerate: () => ctx.read<ReportsBloc>().add(LoadTurnoverReportEvent(_selectedYear)),
                exportUrl: null,
                isLoading: state is ReportsLoading,
                result: state is ReportLoaded && state.reportType == 'turnover' ? state.data : null,
                builder: _buildTurnoverContent,
              ),
              const SizedBox(height: 12),

              // ── Attendance ───────────────────────────────────
              _SectionHeader('Attendance'),
              _ReportCard(
                icon: Icons.fingerprint,
                color: Colors.green,
                title: 'Attendance Summary',
                subtitle: '$_attendanceStart → $_attendanceEnd',
                headerAction: TextButton(
                  onPressed: () => _pickAttendanceDates(ctx),
                  child: const Text('Change dates'),
                ),
                onGenerate: () => ctx.read<ReportsBloc>().add(
                    LoadAttendanceReportEvent(_attendanceStart, _attendanceEnd)),
                exportUrl: sl<ReportsApiService>().getExportUrl('attendance', params: {
                  'start_date': _attendanceStart, 'end_date': _attendanceEnd,
                }),
                isLoading: state is ReportsLoading,
                result: state is ReportLoaded && state.reportType == 'attendance' ? state.data : null,
                builder: _buildAttendanceContent,
              ),
              const SizedBox(height: 12),

              // ── Payroll ──────────────────────────────────────
              _SectionHeader('Payroll'),
              _ReportCard(
                icon: Icons.payments,
                color: Colors.purple,
                title: 'Payroll Summary',
                subtitle: 'Period: $_payrollMonth',
                headerAction: TextButton(
                  onPressed: () => _pickPayrollMonth(ctx),
                  child: const Text('Change month'),
                ),
                onGenerate: () => ctx.read<ReportsBloc>().add(LoadPayrollReportEvent(_payrollMonth)),
                exportUrl: sl<ReportsApiService>().getExportUrl('payroll',
                    params: {'month_year': _payrollMonth}),
                isLoading: state is ReportsLoading,
                result: state is ReportLoaded && state.reportType == 'payroll' ? state.data : null,
                builder: _buildPayrollContent,
              ),
              const SizedBox(height: 12),

              // ── Leave ────────────────────────────────────────
              _SectionHeader('Leave'),
              _ReportCard(
                icon: Icons.beach_access,
                color: Colors.teal,
                title: 'Leave Summary',
                subtitle: 'Year $_selectedYear',
                onGenerate: () => ctx.read<ReportsBloc>().add(LoadLeaveReportEvent(_selectedYear)),
                exportUrl: null,
                isLoading: state is ReportsLoading,
                result: state is ReportLoaded && state.reportType == 'leave' ? state.data : null,
                builder: _buildLeaveContent,
              ),
              const SizedBox(height: 12),

              // ── Custom Export ────────────────────────────────
              _SectionHeader('Custom Export'),
              const _CustomExportCard(),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  // ── Date pickers ──────────────────────────────────────────────

  Future<void> _pickAttendanceDates(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.parse(_attendanceStart),
        end:   DateTime.parse(_attendanceEnd),
      ),
    );
    if (range != null) {
      setState(() {
        _attendanceStart = range.start.toString().substring(0, 10);
        _attendanceEnd   = range.end.toString().substring(0, 10);
      });
    }
  }

  Future<void> _pickPayrollMonth(BuildContext context) async {
    // Simple year/month picker using dialog
    int year  = int.parse(_payrollMonth.split('-')[0]);
    int month = int.parse(_payrollMonth.split('-')[1]);
    final months = List.generate(12, (i) => i + 1);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select Month'),
        content: Wrap(spacing: 8, children: months.map((m) => ChoiceChip(
          label: Text('$year-${m.toString().padLeft(2, '0')}'),
          selected: m == month,
          onSelected: (_) {
            setState(() => _payrollMonth = '$year-${m.toString().padLeft(2, '0')}');
            Navigator.pop(context);
          },
        )).toList()),
      ),
    );
  }

  // ── Report content builders ────────────────────────────────

  Widget _buildHeadcountContent(Map<String, dynamic> data) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _StatRow('Total Active Employees', '${data['total_active'] ?? 0}', Colors.blue),
      const SizedBox(height: 8),
      const Text('By Role', style: TextStyle(fontWeight: FontWeight.w600)),
      ..._mapToRows(data['by_role'] as Map<String, dynamic>? ?? {}, Colors.indigo),
      const SizedBox(height: 8),
      const Text('By Department', style: TextStyle(fontWeight: FontWeight.w600)),
      ..._mapToRows(data['by_department'] as Map<String, dynamic>? ?? {}, Colors.teal),
    ]);
  }

  Widget _buildTurnoverContent(Map<String, dynamic> data) => Column(children: [
    _StatRow('Hires',    '${data['hires'] ?? 0}',    Colors.green),
    _StatRow('Exits',    '${data['exits'] ?? 0}',    Colors.red),
    _StatRow('Turnover', '${data['turnover_rate'] ?? 0}%', Colors.orange),
  ]);

  Widget _buildAttendanceContent(Map<String, dynamic> data) => Column(children: [
    _StatRow('Total Records', '${data['total_records'] ?? 0}', Colors.blue),
    ..._mapToRows(data['by_status'] as Map<String, dynamic>? ?? {}, Colors.green),
  ]);

  Widget _buildPayrollContent(Map<String, dynamic> data) => Column(children: [
    _StatRow('Total Gross', '\$${_fmt(data['total_gross'])}', Colors.blue),
    _StatRow('Deductions',  '\$${_fmt(data['total_deductions'])}', Colors.red),
    _StatRow('Net Total',   '\$${_fmt(data['total_net'])}', Colors.green),
    _StatRow('Records',     '${data['total_records'] ?? 0}', Colors.grey),
  ]);

  Widget _buildLeaveContent(Map<String, dynamic> data) => Column(children: [
    _StatRow('Total Requests', '${data['total_requests'] ?? 0}', Colors.teal),
    ..._mapToRows(data['by_status'] as Map<String, dynamic>? ?? {}, Colors.blue),
    ..._mapToRows(data['by_type'] as Map<String, dynamic>? ?? {}, Colors.purple),
  ]);

  List<Widget> _mapToRows(Map<String, dynamic> map, Color color) =>
      map.entries.map((e) => _StatRow('  ${e.key}', '${e.value}', color)).toList();

  String _fmt(dynamic v) {
    if (v == null) return '0';
    final d = double.tryParse(v.toString()) ?? 0;
    return d.toStringAsFixed(0);
  }
}

// ── Section Header ────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
  );
}

// ── Report Card ───────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? headerAction;
  final VoidCallback onGenerate;
  final String? exportUrl;
  final bool isLoading;
  final Map<String, dynamic>? result;
  final Widget Function(Map<String, dynamic>) builder;

  const _ReportCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.headerAction,
    required this.onGenerate,
    required this.exportUrl,
    required this.isLoading,
    required this.result,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ])),
            if (headerAction != null) headerAction!,
          ]),

          const SizedBox(height: 12),

          // Action buttons
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onGenerate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: isLoading
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.refresh, size: 16),
                label: Text(isLoading ? 'Loading…' : 'Generate'),
              ),
            ),
            if (exportUrl != null) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _openExport(context, exportUrl!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('CSV'),
              ),
            ],
          ]),

          // Result
          if (result != null) ...[
            const Divider(height: 20),
            builder(result!),
          ],
        ]),
      ),
    );
  }

  void _openExport(BuildContext context, String url) {
    // Show the URL — in production use url_launcher to open the browser download
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export URL: $url'),
        action: SnackBarAction(label: 'Copy', onPressed: () {}),
      ),
    );
  }
}

// ── Stat Row ──────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatRow(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Text(value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
      ),
    ]),
  );
}

// ── Custom Export Card ────────────────────────────────────────

class _CustomExportCard extends StatefulWidget {
  const _CustomExportCard();
  @override
  State<_CustomExportCard> createState() => _CustomExportCardState();
}

class _CustomExportCardState extends State<_CustomExportCard> {
  String _entity = 'employees';
  static const _entities = ['employees', 'attendance', 'payroll', 'leaves'];

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.deepOrange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.table_chart, color: Colors.deepOrange),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Custom Data Export', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('Export raw data as CSV or JSON', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ])),
          ]),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: _entities.map((e) => ChoiceChip(
              label: Text(e),
              selected: _entity == e,
              onSelected: (_) => setState(() => _entity = e),
              selectedColor: Colors.deepOrange.withOpacity(0.15),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ElevatedButton.icon(
              onPressed: () => context.read<ReportsBloc>().add(LoadCustomReportEvent(_entity)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.preview, size: 16),
              label: const Text('Preview JSON'),
            )),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () {
                final url = '${sl<ReportsApiService>().getExportUrl('custom')}'
                    '?entity=$_entity&format=csv';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Export: $url')));
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.deepOrange,
                side: const BorderSide(color: Colors.deepOrange),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Export CSV'),
            ),
          ]),
          BlocBuilder<ReportsBloc, ReportsState>(
            builder: (_, state) {
              if (state is ReportLoaded && state.reportType == _entity) {
                final count = (state.data['total_records'] as num?)?.toInt() ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text('✓ $count records loaded',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                );
              }
              return const SizedBox();
            },
          ),
        ]),
      ),
    );
  }
}
