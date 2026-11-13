// lib/features/admin/presentation/admin_screen.dart
//
// AdminScreen — 4-tab administration dashboard
//   Tab 0: System Stats
//   Tab 1: Audit Logs
//   Tab 2: Companies
//   Tab 3: Branches

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import 'bloc/admin_bloc.dart';
import '../data/models/admin_models.dart';

// ─── AdminScreen — outer widget providing BLoC ─────────────────

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminBloc>(),
      child: const _AdminView(),
    );
  }
}

// ─── _AdminView — 4-tab shell ──────────────────────────────────

class _AdminView extends StatefulWidget {
  const _AdminView();

  @override
  State<_AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<_AdminView>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // Keep selected company for Branches tab
  String? _selectedCompanyId;
  String? _selectedCompanyName;

  // Filter state for Audit Logs
  String? _auditActionFilter;

  // Cache companies list for Branches picker
  List<Company> _companiesCache = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);

    // Load initial data for first visible tab
    SchedulerBinding.instance.addPostFrameCallback((_) {
      context.read<AdminBloc>().add(LoadSystemStatsEvent());
    });

    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) return;
      switch (_tabs.index) {
        case 0:
          context.read<AdminBloc>().add(LoadSystemStatsEvent());
          break;
        case 1:
          context.read<AdminBloc>().add(
                LoadAuditLogsEvent(action: _auditActionFilter),
              );
          break;
        case 2:
          context.read<AdminBloc>().add(LoadCompaniesEvent());
          break;
        case 3:
          if (_selectedCompanyId != null) {
            context
                .read<AdminBloc>()
                .add(LoadBranchesEvent(_selectedCompanyId!));
          }
          break;
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Administration'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 2,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          labelStyle: AppTextStyles.titleSmall,
          unselectedLabelStyle: AppTextStyles.bodySmall,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'System Stats'),
            Tab(text: 'Audit Logs'),
            Tab(text: 'Companies'),
            Tab(text: 'Branches'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _SystemStatsTab(onRefresh: () {
            context.read<AdminBloc>().add(LoadSystemStatsEvent());
          }),
          _AuditLogsTab(
            actionFilter: _auditActionFilter,
            onFilterChanged: (val) {
              setState(() => _auditActionFilter = val);
              context
                  .read<AdminBloc>()
                  .add(LoadAuditLogsEvent(action: val));
            },
          ),
          _CompaniesTab(
            onCompaniesLoaded: (companies) {
              _companiesCache = companies;
            },
          ),
          _BranchesTab(
            selectedCompanyId: _selectedCompanyId,
            selectedCompanyName: _selectedCompanyName,
            companiesCache: _companiesCache,
            onCompanySelected: (id, name) {
              setState(() {
                _selectedCompanyId = id;
                _selectedCompanyName = name;
              });
              context.read<AdminBloc>().add(LoadBranchesEvent(id));
            },
          ),
        ],
      ),
    );
  }
}

// ─── Tab 0: System Stats ───────────────────────────────────────

class _SystemStatsTab extends StatelessWidget {
  final VoidCallback onRefresh;

  const _SystemStatsTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => onRefresh(),
          child: _buildContent(context, state),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, AdminState state) {
    if (state is AdminLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (state is AdminError) {
      return AppTheme.errorState(
        message: state.message,
        onRetry: onRefresh,
      );
    }
    if (state is SystemStatsLoaded) {
      return _buildGrid(state.stats);
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 300,
          child: AppTheme.emptyState(
            icon: Icons.bar_chart_rounded,
            title: 'No stats loaded',
            subtitle: 'Pull down to refresh',
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(SystemStats stats) {
    final cards = [
      _StatData(
        label: 'Total Employees',
        value: stats.totalEmployees,
        icon: Icons.people_rounded,
        color: AppColors.primary,
      ),
      _StatData(
        label: 'Active Employees',
        value: stats.activeEmployees,
        icon: Icons.person_rounded,
        color: AppColors.success,
      ),
      _StatData(
        label: 'Departments',
        value: stats.totalDepartments,
        icon: Icons.account_tree_rounded,
        color: AppColors.secondary,
      ),
      _StatData(
        label: 'Pending Leaves',
        value: stats.pendingLeaveRequests,
        icon: Icons.beach_access_rounded,
        color: AppColors.warning,
      ),
      _StatData(
        label: 'Open Jobs',
        value: stats.openJobs,
        icon: Icons.work_rounded,
        color: AppColors.info,
      ),
      _StatData(
        label: 'Total Candidates',
        value: stats.totalCandidates,
        icon: Icons.badge_rounded,
        color: AppColors.primaryDark,
      ),
      _StatData(
        label: 'Payroll Pending',
        value: stats.pendingPayroll,
        icon: Icons.payments_rounded,
        color: AppColors.error,
      ),
      _StatData(
        label: 'Audit Logs Today',
        value: stats.auditLogsToday,
        icon: Icons.security_rounded,
        color: AppColors.textSecondary,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.3,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      physics: const AlwaysScrollableScrollPhysics(),
      children: cards.map((d) => _StatCard(data: d)).toList(),
    );
  }
}

class _StatData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  final _StatData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.statCardDecoration(data.color),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, size: 22, color: data.color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value.toString(),
                style: AppTextStyles.displaySmall.copyWith(color: data.color),
              ),
              const SizedBox(height: 2),
              Text(
                data.label,
                style: AppTextStyles.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Audit Logs ─────────────────────────────────────────

class _AuditLogsTab extends StatelessWidget {
  final String? actionFilter;
  final ValueChanged<String?> onFilterChanged;

  const _AuditLogsTab({
    required this.actionFilter,
    required this.onFilterChanged,
  });

  static const _actions = [
    'CREATE',
    'UPDATE',
    'DELETE',
    'LOGIN',
    'LOGOUT',
    'EXPORT',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: actionFilter,
                      hint: Text('All Actions',
                          style: AppTextStyles.bodyMedium),
                      isExpanded: true,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Actions'),
                        ),
                        ..._actions.map(
                          (a) => DropdownMenuItem(value: a, child: Text(a)),
                        ),
                      ],
                      onChanged: onFilterChanged,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => context.read<AdminBloc>().add(
                      LoadAuditLogsEvent(action: actionFilter),
                    ),
                icon: const Icon(Icons.refresh_rounded),
                color: AppColors.primary,
                tooltip: 'Reload',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<AdminBloc, AdminState>(
            builder: (context, state) {
              if (state is AdminLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (state is AdminError) {
                return AppTheme.errorState(
                  message: state.message,
                  onRetry: () => context.read<AdminBloc>().add(
                        LoadAuditLogsEvent(action: actionFilter),
                      ),
                );
              }
              if (state is AuditLogsLoaded) {
                if (state.logs.isEmpty) {
                  return AppTheme.emptyState(
                    icon: Icons.history_rounded,
                    title: 'No audit logs',
                    subtitle: 'Nothing to show for the selected filter',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _AuditLogCard(log: state.logs[i]),
                );
              }
              return AppTheme.emptyState(
                icon: Icons.history_rounded,
                title: 'No audit logs loaded',
                subtitle: 'Select a filter and tap reload',
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AuditLogCard extends StatelessWidget {
  final AuditLog log;

  const _AuditLogCard({required this.log});

  Color _actionColor(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return AppColors.success;
      case 'UPDATE':
        return AppColors.warning;
      case 'DELETE':
        return AppColors.error;
      case 'LOGIN':
        return AppColors.primary;
      case 'LOGOUT':
        return AppColors.secondary;
      case 'EXPORT':
        return AppColors.info;
      default:
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _actionColor(log.action);
    return Container(
      decoration: AppTheme.cardDecoration(radius: 12),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              log.action.toUpperCase(),
              style: AppTextStyles.labelBold.copyWith(color: color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (log.actorEmail != null)
                  Text(
                    log.actorEmail!,
                    style: AppTextStyles.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                Text(
                  '${log.entityType}${log.entityId != null ? ' · ${log.entityId}' : ''}',
                  style: AppTextStyles.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (log.description != null && log.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    log.description!,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (log.ipAddress != null) ...[
                      Icon(Icons.language_rounded,
                          size: 11, color: AppColors.textHint),
                      const SizedBox(width: 3),
                      Text(log.ipAddress!,
                          style: AppTextStyles.captionText),
                      const SizedBox(width: 10),
                    ],
                    if (log.createdAt != null) ...[
                      Icon(Icons.access_time_rounded,
                          size: 11, color: AppColors.textHint),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          _formatDate(log.createdAt!),
                          style: AppTextStyles.captionText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.year}-${_p(dt.month)}-${_p(dt.day)} '
          '${_p(dt.hour)}:${_p(dt.minute)}';
    } catch (_) {
      return raw;
    }
  }

  String _p(int n) => n.toString().padLeft(2, '0');
}

// ─── Tab 2: Companies ──────────────────────────────────────────

class _CompaniesTab extends StatelessWidget {
  final ValueChanged<List<Company>> onCompaniesLoaded;

  const _CompaniesTab({required this.onCompaniesLoaded});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is CompanyCreated) {
          AppTheme.showSnackBar(context, 'Company "${state.company.name}" created');
          context.read<AdminBloc>().add(LoadCompaniesEvent());
        } else if (state is CompanyUpdated) {
          AppTheme.showSnackBar(context, 'Company "${state.company.name}" updated');
          context.read<AdminBloc>().add(LoadCompaniesEvent());
        } else if (state is CompanyDeleted) {
          AppTheme.showSnackBar(context, 'Company deleted');
          context.read<AdminBloc>().add(LoadCompaniesEvent());
        } else if (state is AdminError) {
          AppTheme.showSnackBar(context, state.message, isError: true);
        }
        if (state is CompaniesLoaded) {
          onCompaniesLoaded(state.companies);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCompanyForm(context, company: null),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add_rounded),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AdminState state) {
    if (state is AdminLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (state is AdminError) {
      return AppTheme.errorState(
        message: state.message,
        onRetry: () => context.read<AdminBloc>().add(LoadCompaniesEvent()),
      );
    }
    if (state is CompaniesLoaded) {
      if (state.companies.isEmpty) {
        return AppTheme.emptyState(
          icon: Icons.business_rounded,
          title: 'No companies yet',
          subtitle: 'Tap + to add the first company',
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: state.companies.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _CompanyCard(
          company: state.companies[i],
          onEdit: () =>
              _showCompanyForm(context, company: state.companies[i]),
          onDelete: () =>
              _confirmDelete(context, state.companies[i]),
        ),
      );
    }
    return AppTheme.emptyState(
      icon: Icons.business_rounded,
      title: 'Companies',
      subtitle: 'Loading…',
    );
  }

  void _showCompanyForm(BuildContext context, {Company? company}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<AdminBloc>(),
        child: _CompanyFormSheet(company: company),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Company company) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Company'),
        content: Text(
            'Are you sure you want to delete "${company.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: AppTheme.dangerButtonStyle(),
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<AdminBloc>()
                  .add(DeleteCompanyEvent(company.id));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final Company company;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CompanyCard({
    required this.company,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration(radius: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.business_rounded,
              color: AppColors.primary, size: 22),
        ),
        title: Text(company.name, style: AppTextStyles.titleSmall),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (company.legalName != null)
              Text(company.legalName!, style: AppTextStyles.bodySmall),
            const SizedBox(height: 4),
            Row(
              children: [
                _Chip(label: company.currency, color: AppColors.primary),
                const SizedBox(width: 6),
                _Chip(label: company.timezone, color: AppColors.secondary),
                const SizedBox(width: 6),
                _Chip(
                  label: company.isActive ? 'Active' : 'Inactive',
                  color: company.isActive
                      ? AppColors.success
                      : AppColors.error,
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, size: 18),
              color: AppColors.textSecondary,
              tooltip: 'Edit',
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_rounded, size: 18),
              color: AppColors.error,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyFormSheet extends StatefulWidget {
  final Company? company;

  const _CompanyFormSheet({this.company});

  @override
  State<_CompanyFormSheet> createState() => _CompanyFormSheetState();
}

class _CompanyFormSheetState extends State<_CompanyFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _legalName;
  late final TextEditingController _regNumber;
  late final TextEditingController _country;
  late final TextEditingController _timezone;
  late final TextEditingController _currency;

  @override
  void initState() {
    super.initState();
    final c = widget.company;
    _name = TextEditingController(text: c?.name ?? '');
    _legalName = TextEditingController(text: c?.legalName ?? '');
    _regNumber =
        TextEditingController(text: c?.registrationNumber ?? '');
    _country = TextEditingController(text: c?.country ?? '');
    _timezone = TextEditingController(text: c?.timezone ?? 'UTC');
    _currency = TextEditingController(text: c?.currency ?? 'USD');
  }

  @override
  void dispose() {
    _name.dispose();
    _legalName.dispose();
    _regNumber.dispose();
    _country.dispose();
    _timezone.dispose();
    _currency.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final isEdit = widget.company != null;

    if (isEdit) {
      context.read<AdminBloc>().add(
            UpdateCompanyEvent(widget.company!.id, {
              'name': _name.text.trim(),
              'legal_name': _legalName.text.trim(),
              'registration_number': _regNumber.text.trim(),
              'country': _country.text.trim(),
              'timezone': _timezone.text.trim(),
              'currency': _currency.text.trim().toUpperCase(),
            }),
          );
    } else {
      context.read<AdminBloc>().add(
            CreateCompanyEvent(
              Company(
                id: '',
                name: _name.text.trim(),
                legalName: _legalName.text.trim().isEmpty
                    ? null
                    : _legalName.text.trim(),
                registrationNumber:
                    _regNumber.text.trim().isEmpty
                        ? null
                        : _regNumber.text.trim(),
                country: _country.text.trim().isEmpty
                    ? null
                    : _country.text.trim(),
                timezone: _timezone.text.trim().isEmpty
                    ? 'UTC'
                    : _timezone.text.trim(),
                currency: _currency.text.trim().isEmpty
                    ? 'USD'
                    : _currency.text.trim().toUpperCase(),
              ),
            ),
          );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.company != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  isEdit ? 'Edit Company' : 'New Company',
                  style: AppTextStyles.titleMedium,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                decoration: AppTheme.inputDecoration('Company Name *',
                    icon: Icons.business_rounded),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _legalName,
                decoration: AppTheme.inputDecoration('Legal Name',
                    icon: Icons.gavel_rounded),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _regNumber,
                decoration: AppTheme.inputDecoration(
                    'Registration Number',
                    icon: Icons.numbers_rounded),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _country,
                decoration: AppTheme.inputDecoration('Country',
                    icon: Icons.flag_rounded),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _timezone,
                decoration: AppTheme.inputDecoration('Timezone',
                    icon: Icons.schedule_rounded),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _currency,
                decoration: AppTheme.inputDecoration('Currency (e.g. USD)',
                    icon: Icons.attach_money_rounded),
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: AppTheme.primaryButtonStyle(),
                child: Text(isEdit ? 'Save Changes' : 'Create Company'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab 3: Branches ───────────────────────────────────────────

class _BranchesTab extends StatelessWidget {
  final String? selectedCompanyId;
  final String? selectedCompanyName;
  final List<Company> companiesCache;
  final void Function(String id, String name) onCompanySelected;

  const _BranchesTab({
    required this.selectedCompanyId,
    required this.selectedCompanyName,
    required this.companiesCache,
    required this.onCompanySelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is BranchCreated) {
          AppTheme.showSnackBar(
              context, 'Branch "${state.branch.name}" created');
          if (selectedCompanyId != null) {
            context
                .read<AdminBloc>()
                .add(LoadBranchesEvent(selectedCompanyId!));
          }
        } else if (state is BranchUpdated) {
          AppTheme.showSnackBar(
              context, 'Branch "${state.branch.name}" updated');
          if (selectedCompanyId != null) {
            context
                .read<AdminBloc>()
                .add(LoadBranchesEvent(selectedCompanyId!));
          }
        } else if (state is BranchDeleted) {
          AppTheme.showSnackBar(context, 'Branch deleted');
          if (selectedCompanyId != null) {
            context
                .read<AdminBloc>()
                .add(LoadBranchesEvent(selectedCompanyId!));
          }
        } else if (state is AdminError) {
          AppTheme.showSnackBar(context, state.message, isError: true);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          floatingActionButton: selectedCompanyId != null
              ? FloatingActionButton(
                  onPressed: () =>
                      _showBranchForm(context, branch: null),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.add_rounded),
                )
              : null,
          body: Column(
            children: [
              _buildCompanyPicker(context),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompanyPicker(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCompanyPickerDialog(context),
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.business_rounded,
                  size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Company', style: AppTextStyles.captionText),
                  Text(
                    selectedCompanyName ?? 'Select a company',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: selectedCompanyName != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded,
                color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  void _showCompanyPickerDialog(BuildContext context) {
    // Load companies first if cache is empty
    if (companiesCache.isEmpty) {
      context.read<AdminBloc>().add(LoadCompaniesEvent());
    }

    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AdminBloc>(),
        child: AlertDialog(
          title: const Text('Select Company'),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12),
          content: SizedBox(
            width: double.maxFinite,
            child: BlocBuilder<AdminBloc, AdminState>(
              builder: (ctx, state) {
                List<Company> companies = [];
                if (state is CompaniesLoaded) {
                  companies = state.companies;
                } else if (companiesCache.isNotEmpty) {
                  companies = companiesCache;
                }
                if (companies.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: companies.length,
                  itemBuilder: (_, i) {
                    final c = companies[i];
                    return ListTile(
                      title: Text(c.name,
                          style: AppTextStyles.titleSmall),
                      subtitle: c.country != null
                          ? Text(c.country!,
                              style: AppTextStyles.bodySmall)
                          : null,
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.business_rounded,
                            color: AppColors.primary, size: 18),
                      ),
                      selected: c.id == selectedCompanyId,
                      selectedTileColor: AppColors.primaryLight,
                      onTap: () {
                        Navigator.pop(context);
                        onCompanySelected(c.id, c.name);
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AdminState state) {
    if (selectedCompanyId == null) {
      return AppTheme.emptyState(
        icon: Icons.account_tree_rounded,
        title: 'Select a company to view branches',
        subtitle: 'Tap the company picker above',
      );
    }
    if (state is AdminLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (state is AdminError) {
      return AppTheme.errorState(
        message: state.message,
        onRetry: () => context
            .read<AdminBloc>()
            .add(LoadBranchesEvent(selectedCompanyId!)),
      );
    }
    if (state is BranchesLoaded) {
      if (state.branches.isEmpty) {
        return AppTheme.emptyState(
          icon: Icons.location_city_rounded,
          title: 'No branches yet',
          subtitle: 'Tap + to add the first branch',
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: state.branches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _BranchCard(
          branch: state.branches[i],
          onEdit: () =>
              _showBranchForm(context, branch: state.branches[i]),
          onDelete: () =>
              _confirmBranchDelete(context, state.branches[i]),
        ),
      );
    }
    return AppTheme.emptyState(
      icon: Icons.location_city_rounded,
      title: 'Loading branches…',
    );
  }

  void _showBranchForm(BuildContext context, {Branch? branch}) {
    if (selectedCompanyId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<AdminBloc>(),
        child: _BranchFormSheet(
          branch: branch,
          companyId: selectedCompanyId!,
        ),
      ),
    );
  }

  void _confirmBranchDelete(BuildContext context, Branch branch) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Branch'),
        content: Text(
            'Are you sure you want to delete "${branch.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: AppTheme.dangerButtonStyle(),
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<AdminBloc>()
                  .add(DeleteBranchEvent(branch.id));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  final Branch branch;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BranchCard({
    required this.branch,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration(radius: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.secondaryBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.location_city_rounded,
              color: AppColors.secondary, size: 22),
        ),
        title: Text(branch.name, style: AppTextStyles.titleSmall),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (branch.code != null)
              Text('Code: ${branch.code}',
                  style: AppTextStyles.bodySmall),
            if (branch.city != null || branch.country != null)
              Text(
                [branch.city, branch.country]
                    .where((e) => e != null)
                    .join(', '),
                style: AppTextStyles.bodySmall,
              ),
            if (branch.email != null)
              Text(branch.email!, style: AppTextStyles.captionText),
            const SizedBox(height: 4),
            _Chip(
              label: branch.isActive ? 'Active' : 'Inactive',
              color: branch.isActive ? AppColors.success : AppColors.error,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, size: 18),
              color: AppColors.textSecondary,
              tooltip: 'Edit',
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_rounded, size: 18),
              color: AppColors.error,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchFormSheet extends StatefulWidget {
  final Branch? branch;
  final String companyId;

  const _BranchFormSheet({
    this.branch,
    required this.companyId,
  });

  @override
  State<_BranchFormSheet> createState() => _BranchFormSheetState();
}

class _BranchFormSheetState extends State<_BranchFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _country;
  late final TextEditingController _phone;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    final b = widget.branch;
    _name = TextEditingController(text: b?.name ?? '');
    _code = TextEditingController(text: b?.code ?? '');
    _address = TextEditingController(text: b?.address ?? '');
    _city = TextEditingController(text: b?.city ?? '');
    _country = TextEditingController(text: b?.country ?? '');
    _phone = TextEditingController(text: b?.phone ?? '');
    _email = TextEditingController(text: b?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _address.dispose();
    _city.dispose();
    _country.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final isEdit = widget.branch != null;

    if (isEdit) {
      context.read<AdminBloc>().add(
            UpdateBranchEvent(widget.branch!.id, {
              'name': _name.text.trim(),
              'code': _code.text.trim(),
              'address': _address.text.trim(),
              'city': _city.text.trim(),
              'country': _country.text.trim(),
              'phone': _phone.text.trim(),
              'email': _email.text.trim(),
            }),
          );
    } else {
      context.read<AdminBloc>().add(
            CreateBranchEvent(
              Branch(
                id: '',
                companyId: widget.companyId,
                name: _name.text.trim(),
                code: _code.text.trim().isEmpty
                    ? null
                    : _code.text.trim(),
                address: _address.text.trim().isEmpty
                    ? null
                    : _address.text.trim(),
                city: _city.text.trim().isEmpty
                    ? null
                    : _city.text.trim(),
                country: _country.text.trim().isEmpty
                    ? null
                    : _country.text.trim(),
                phone: _phone.text.trim().isEmpty
                    ? null
                    : _phone.text.trim(),
                email: _email.text.trim().isEmpty
                    ? null
                    : _email.text.trim(),
              ),
            ),
          );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.branch != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  isEdit ? 'Edit Branch' : 'New Branch',
                  style: AppTextStyles.titleMedium,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                decoration: AppTheme.inputDecoration('Branch Name *',
                    icon: Icons.location_city_rounded),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _code,
                decoration: AppTheme.inputDecoration('Branch Code',
                    icon: Icons.tag_rounded),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _address,
                decoration: AppTheme.inputDecoration('Address',
                    icon: Icons.home_rounded),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _city,
                decoration: AppTheme.inputDecoration('City',
                    icon: Icons.location_on_rounded),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _country,
                decoration: AppTheme.inputDecoration('Country',
                    icon: Icons.flag_rounded),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                decoration: AppTheme.inputDecoration('Phone',
                    icon: Icons.phone_rounded),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                decoration: AppTheme.inputDecoration('Email',
                    icon: Icons.email_rounded),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: AppTheme.primaryButtonStyle(),
                child: Text(isEdit ? 'Save Changes' : 'Create Branch'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared Helpers ────────────────────────────────────────────

/// A small coloured label chip
class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionText.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
