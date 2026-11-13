// lib/features/recruitment/presentation/recruitment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import 'bloc/recruitment_bloc.dart';
import '../data/models/recruitment_models.dart';

class RecruitmentScreen extends StatelessWidget {
  const RecruitmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RecruitmentBloc>()..add(LoadJobsEvent()),
      child: const _RecruitmentView(),
    );
  }
}

class _RecruitmentView extends StatefulWidget {
  const _RecruitmentView();
  @override
  State<_RecruitmentView> createState() => _RecruitmentViewState();
}

class _RecruitmentViewState extends State<_RecruitmentView>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _statusFilter = 'OPEN';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Recruitment'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.work_outline), text: 'Jobs'),
            Tab(icon: Icon(Icons.people_outline), text: 'Candidates'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Interviews'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateJobDialog(context),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Post Job', style: TextStyle(color: Colors.white)),
      ),
      body: BlocConsumer<RecruitmentBloc, RecruitmentState>(
        listener: (ctx, state) {
          if (state is RecruitmentSuccess) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green));
            ctx.read<RecruitmentBloc>().add(LoadJobsEvent());
          }
          if (state is RecruitmentError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (ctx, state) {
          return TabBarView(
            controller: _tabs,
            children: [
              _JobsTab(statusFilter: _statusFilter, onFilterChange: (f) {
                setState(() => _statusFilter = f);
                ctx.read<RecruitmentBloc>().add(LoadJobsEvent(statusFilter: f));
              }),
              const _CandidatesTab(),
              const _InterviewsTab(),
            ],
          );
        },
      ),
    );
  }

  void _showCreateJobDialog(BuildContext context) {
    final titleC = TextEditingController();
    final descC  = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Post New Job'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleC, decoration: const InputDecoration(labelText: 'Job Title *')),
          const SizedBox(height: 12),
          TextField(controller: descC, maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description *')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () {
              if (titleC.text.isEmpty || descC.text.isEmpty) return;
              context.read<RecruitmentBloc>().add(CreateJobEvent(
                JobPosting(title: titleC.text, description: descC.text),
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

// ── Jobs Tab ──────────────────────────────────────────────────

class _JobsTab extends StatelessWidget {
  final String statusFilter;
  final ValueChanged<String> onFilterChange;
  const _JobsTab({required this.statusFilter, required this.onFilterChange});

  static const _statuses = ['OPEN', 'DRAFT', 'PAUSED', 'CLOSED', 'FILLED'];
  static const _statusColors = {
    'OPEN': Colors.green, 'DRAFT': Colors.grey, 'PAUSED': Colors.orange,
    'CLOSED': Colors.red, 'FILLED': Colors.blue,
  };

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Filter chips
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _statuses.map((s) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(s),
                selected: statusFilter == s,
                onSelected: (_) => onFilterChange(s),
                selectedColor: AppTheme.primaryColor.withOpacity(0.15),
              ),
            )).toList(),
          ),
        ),
      ),
      Expanded(child: BlocBuilder<RecruitmentBloc, RecruitmentState>(
        builder: (ctx, state) {
          if (state is RecruitmentLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is JobsLoaded) {
            if (state.jobs.isEmpty) {
              return _EmptyState(icon: Icons.work_off, label: 'No $statusFilter jobs');
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.jobs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _JobCard(
                job: state.jobs[i],
                statusColor: _statusColors[state.jobs[i].status] ?? Colors.grey,
                onTap: () => _openJobDetail(ctx, state.jobs[i]),
              ),
            );
          }
          return const SizedBox();
        },
      )),
    ]);
  }

  void _openJobDetail(BuildContext context, JobPosting job) {
    if (job.id == null) return;
    context.read<RecruitmentBloc>().add(LoadJobDetailEvent(job.id!));
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<RecruitmentBloc>(),
        child: _JobDetailScreen(job: job),
      ),
    ));
  }
}

class _JobCard extends StatelessWidget {
  final JobPosting job;
  final Color statusColor;
  final VoidCallback onTap;
  const _JobCard({required this.job, required this.statusColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(job.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(job.status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 6),
            if (job.location != null)
              Row(children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(job.location!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
            const SizedBox(height: 8),
            Row(children: [
              _Chip(Icons.work, job.jobType.replaceAll('_', ' ')),
              const SizedBox(width: 8),
              _Chip(Icons.people, '${job.vacancies} vacancies'),
              const SizedBox(width: 8),
              _Chip(Icons.check_circle, '${job.filled} filled'),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 13, color: AppTheme.primaryColor),
    const SizedBox(width: 3),
    Text(label, style: TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
  ]);
}

// ── Job Detail Screen ─────────────────────────────────────────

class _JobDetailScreen extends StatelessWidget {
  final JobPosting job;
  const _JobDetailScreen({required this.job});

  static const _stageColors = {
    'APPLIED': Colors.blue, 'SCREENING': Colors.orange, 'INTERVIEW': Colors.purple,
    'OFFER': Colors.teal, 'HIRED': Colors.green, 'REJECTED': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text(job.title),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<RecruitmentBloc, RecruitmentState>(
        builder: (ctx, state) {
          if (state is RecruitmentLoading) return const Center(child: CircularProgressIndicator());
          if (state is JobDetailLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Pipeline summary
                if (state.pipeline != null) _PipelineCard(summary: state.pipeline!),
                const SizedBox(height: 16),
                // Candidate list
                Text('Candidates (${state.candidates.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                if (state.candidates.isEmpty)
                  const _EmptyState(icon: Icons.person_off, label: 'No candidates yet'),
                ...state.candidates.map((c) => _CandidateCard(
                  candidate: c,
                  stageColor: _stageColors[c.stage] ?? Colors.grey,
                  onStageChange: (newStage) => ctx.read<RecruitmentBloc>()
                      .add(UpdateCandidateStageEvent(c.id!, newStage)),
                )),
              ]),
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () => _showScheduleInterviewDialog(context),
        icon: const Icon(Icons.video_call, color: Colors.white),
        label: const Text('Schedule Interview', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showScheduleInterviewDialog(BuildContext context) {
    // Simple dialog — full form would need candidate selector
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Select a candidate first to schedule an interview')));
  }
}

class _PipelineCard extends StatelessWidget {
  final PipelineSummary summary;
  const _PipelineCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final stages = [
      ('Applied', summary.applied, Colors.blue),
      ('Screening', summary.screening, Colors.orange),
      ('Interview', summary.interview, Colors.purple),
      ('Offer', summary.offer, Colors.teal),
      ('Hired', summary.hired, Colors.green),
      ('Rejected', summary.rejected, Colors.red),
    ];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Pipeline — ${summary.totalCandidates} total',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: stages.map((s) => _PipelineChip(
              label: s.$1, count: s.$2, color: s.$3)).toList(),
          ),
        ]),
      ),
    );
  }
}

class _PipelineChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _PipelineChip({required this.label, required this.count, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
      Text(label, style: TextStyle(color: color, fontSize: 11)),
    ]),
  );
}

class _CandidateCard extends StatelessWidget {
  final Candidate candidate;
  final Color stageColor;
  final ValueChanged<String> onStageChange;
  const _CandidateCard({required this.candidate, required this.stageColor, required this.onStageChange});

  static const _stages = ['APPLIED', 'SCREENING', 'INTERVIEW', 'OFFER', 'HIRED', 'REJECTED', 'WITHDRAWN'];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: stageColor.withOpacity(0.15),
            child: Text(candidate.firstName.isNotEmpty ? candidate.firstName[0] : '?',
                style: TextStyle(color: stageColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(candidate.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(candidate.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (candidate.currentPosition != null)
              Text(candidate.currentPosition!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ])),
          PopupMenuButton<String>(
            initialValue: candidate.stage,
            onSelected: (s) {
              if (candidate.id != null) onStageChange(s);
            },
            itemBuilder: (_) => _stages.map((s) => PopupMenuItem(value: s,
              child: Text(s, style: TextStyle(
                color: s == candidate.stage ? AppTheme.primaryColor : null,
                fontWeight: s == candidate.stage ? FontWeight.bold : null,
              )))).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: stageColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(candidate.stage, style: TextStyle(color: stageColor, fontSize: 11, fontWeight: FontWeight.w600)),
                Icon(Icons.arrow_drop_down, size: 16, color: stageColor),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Candidates Tab ────────────────────────────────────────────

class _CandidatesTab extends StatelessWidget {
  const _CandidatesTab();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.people_outline, size: 64, color: Colors.grey),
        SizedBox(height: 12),
        Text('Select a job to view candidates', style: TextStyle(color: Colors.grey)),
      ]),
    );
  }
}

// ── Interviews Tab ────────────────────────────────────────────

class _InterviewsTab extends StatelessWidget {
  const _InterviewsTab();

  @override
  Widget build(BuildContext context) {
    // Load upcoming interviews on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecruitmentBloc>().add(LoadInterviewsEvent(upcomingOnly: true));
    });

    return BlocBuilder<RecruitmentBloc, RecruitmentState>(
      builder: (ctx, state) {
        if (state is RecruitmentLoading) return const Center(child: CircularProgressIndicator());
        if (state is InterviewsLoaded) {
          if (state.interviews.isEmpty) {
            return const _EmptyState(icon: Icons.event_busy, label: 'No upcoming interviews');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.interviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _InterviewCard(interview: state.interviews[i]),
          );
        }
        return const _EmptyState(icon: Icons.calendar_today, label: 'Tap a job to load interviews');
      },
    );
  }
}

class _InterviewCard extends StatelessWidget {
  final Interview interview;
  const _InterviewCard({required this.interview});

  static const _statusColors = {
    'SCHEDULED': Colors.blue, 'COMPLETED': Colors.green,
    'CANCELLED': Colors.red,  'NO_SHOW':   Colors.orange,
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[interview.status] ?? Colors.grey;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(width: 4, height: 50, color: color, margin: const EdgeInsets.only(right: 12)),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Round ${interview.interviewRound} — ${interview.interviewType ?? "Interview"}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.access_time, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text(interview.scheduledAt.substring(0, 16),
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
            if (interview.location != null)
              Row(children: [
                const Icon(Icons.location_on, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(interview.location!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
          ])),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(interview.status,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
            if (interview.mode.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(interview.mode, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ]),
        ]),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyState({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 56, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      Text(label, style: TextStyle(color: Colors.grey.shade500)),
    ]),
  );
}

