import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../data/employee_api_service.dart';
import '../data/models/employee_model.dart';
import 'add_employee.dart';
import 'employee_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final EmployeeApiService _apiService = GetIt.instance<EmployeeApiService>();
  final TextEditingController _searchController = TextEditingController();

  List<Employee> _allEmployees      = [];
  List<Employee> _filteredEmployees = [];
  bool   _isLoading    = true;
  String _errorMessage = '';
  String _userRole     = '';
  String _userEmail    = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole  = prefs.getString('role')  ?? 'STAFF';
      _userEmail = prefs.getString('email') ?? '';
    });
    await _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    final result = await _apiService.getEmployees();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() { _isLoading = false; _errorMessage = failure.message; }),
      (employees) => setState(() {
        _isLoading        = false;
        _allEmployees     = employees;
        _filteredEmployees = employees;
      }),
    );
  }

  void _search(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filteredEmployees = _allEmployees.where((e) =>
          e.fullName.toLowerCase().contains(lower) ||
          e.email.toLowerCase().contains(lower) ||
          e.position.toLowerCase().contains(lower)).toList();
    });
  }

  Future<void> _deleteEmployee(String id) async {
    final result = await _apiService.deleteEmployee(id);
    if (!mounted) return;
    result.fold(
      (f) => _showSnack(f.message, isError: true),
      (_) { _showSnack('Employee removed successfully'); _loadEmployees(); },
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  // ── Stats helpers ─────────────────────────────────────────────
  int get _adminCount   => _allEmployees.where((e) => e.role == 'ADMIN').length;
  int get _managerCount => _allEmployees.where((e) => e.role == 'MANAGER').length;
  int get _staffCount   => _allEmployees.where((e) => e.role == 'STAFF').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? _buildLoader()
            : _errorMessage.isNotEmpty
                ? _buildError()
                : _buildBody(),
      ),
      floatingActionButton: _userRole == 'ADMIN'
          ? FloatingActionButton.extended(
              heroTag: 'add_emp',
              onPressed: () async {
                final added = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEmployeeScreen()),
                );
                if (added == true) _loadEmployees();
              },
              backgroundColor: AppColors.primary,
              elevation: 2,
              icon: const Icon(Icons.person_add_rounded, color: Colors.white),
              label: const Text('Add Employee',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  // ── Main body ─────────────────────────────────────────────────
  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _loadEmployees,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          // ── App Bar ───────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader()),

          // ── Stat Cards ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: _buildStatRow(),
            ),
          ),

          // ── Search ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _buildSearchBar(),
            ),
          ),

          // ── Section title ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Employee Directory', style: AppTextStyles.titleMedium),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_filteredEmployees.length} members',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Employee list ─────────────────────────────────────
          _filteredEmployees.isEmpty
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48,
                            color: AppColors.textHint),
                        SizedBox(height: 12),
                        Text('No employees found',
                            style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _buildEmployeeCard(_filteredEmployees[i]),
                      childCount: _filteredEmployees.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader() {
    final displayName = _userEmail.isNotEmpty
        ? _userEmail.split('@')[0]
        : 'User';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good day 👋', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  displayName.length > 1
                      ? '${displayName[0].toUpperCase()}${displayName.substring(1)}'
                      : displayName.toUpperCase(),
                  style: AppTextStyles.displayMedium,
                ),
              ],
            ),
          ),
          AppTheme.roleBadge(_userRole),
          const SizedBox(width: 8),
          _buildIconBtn(Icons.refresh_rounded, _loadEmployees),
        ],
      ),
    );
  }

  // ── Stat row ──────────────────────────────────────────────────
  Widget _buildStatRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Row(
          children: [
            _statCard('Total',    '${_allEmployees.length}', Icons.groups_rounded,          AppColors.primary),
            const SizedBox(width: 12),
            _statCard('Admins',   '$_adminCount',            Icons.shield_rounded,           const Color(0xFF7C3AED)),
            const SizedBox(width: 12),
            _statCard('Managers', '$_managerCount',          Icons.manage_accounts_rounded,  const Color(0xFFEA580C)),
            const SizedBox(width: 12),
            _statCard('Staff',    '$_staffCount',            Icons.person_rounded,           AppColors.success),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: AppTextStyles.displayMedium.copyWith(color: color, fontSize: 24)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _search,
      decoration: AppTheme.inputDecoration(
        'Search by name, email or position…',
        icon: Icons.search_rounded,
        suffix: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () { _searchController.clear(); _search(''); },
              )
            : null,
      ),
    );
  }

  // ── Employee card ─────────────────────────────────────────────
  Widget _buildEmployeeCard(Employee emp) {
    final initials = (emp.firstName.isNotEmpty ? emp.firstName[0] : '') +
        (emp.lastName.isNotEmpty  ? emp.lastName[0]  : '');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecoration(radius: 14),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => EmployeeDetailScreen(employee: emp)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primaryLight,
          child: Text(
            initials.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 14,
            ),
          ),
        ),
        title: Text(emp.fullName, style: AppTextStyles.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(emp.position, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 2),
            Text(emp.email, style: AppTextStyles.bodySmall),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AppTheme.roleBadge(emp.role),
            if (_userRole == 'ADMIN') ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _confirmDelete(emp.id ?? ''),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.error),
                ),
              ),
            ],
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  // ── Delete dialog ─────────────────────────────────────────────
  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.errorLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.delete_forever_rounded,
              color: AppColors.error, size: 28),
        ),
        title: const Text('Remove Employee', style: AppTextStyles.titleLarge),
        content: Text(
          'This action cannot be undone. The employee record will be permanently deleted.',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: AppTheme.dangerButtonStyle(),
            onPressed: () { Navigator.pop(ctx); _deleteEmployee(id); },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Icon button helper ────────────────────────────────────────
  Widget _buildIconBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  // ── Loading / Error states ────────────────────────────────────
  Widget _buildLoader() => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi_off_rounded,
                    size: 40, color: AppColors.error),
              ),
              const SizedBox(height: 16),
              Text(_errorMessage,
                  style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: AppTheme.primaryButtonStyle(),
                onPressed: _loadEmployees,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
}
