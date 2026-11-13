// lib/core/utils/constants.dart

import 'package:flutter/material.dart';

class AppConstants {
  // ── API Base URL ──────────────────────────────────────────────
  static const String baseUrl = 'http://127.0.0.1:8000';

  // ── Auth ──────────────────────────────────────────────────────
  static const String loginEndpoint    = '/api/v1/login';
  static const String registerEndpoint = '/api/v1/register';

  // ── Employees ─────────────────────────────────────────────────
  static const String employeesEndpoint     = '/api/v1/employees';
  static const String employeeStatsEndpoint = '/api/v1/employees/stats';
  static const String designationsEndpoint  = '/api/v1/employees/designations';
  static const String expiringDocsEndpoint  = '/api/v1/employees/documents/expiring-soon';
  static String employeeProfileEndpoint(String id)       => '/api/v1/employees/$id/profile';
  static String employeeStatusEndpoint(String id)        => '/api/v1/employees/$id/status';
  static String employeeManagerEndpoint(String id)       => '/api/v1/employees/$id/manager';
  static String employeeDirectReportsEndpoint(String id) => '/api/v1/employees/$id/direct-reports';
  static String employeeOrgChartEndpoint(String id)      => '/api/v1/employees/$id/org-chart';
  static String employeeDocumentsEndpoint(String id)     => '/api/v1/employees/$id/documents';
  static String employeeDocUploadEndpoint(String id)     => '/api/v1/employees/$id/documents/upload';
  static String documentEndpoint(String docId)           => '/api/v1/employees/documents/$docId';
  static String designationEndpoint(String id)           => '/api/v1/employees/designations/$id';

  // ── Departments ───────────────────────────────────────────────
  static const String departmentsEndpoint = '/api/v1/departments';

  // ── Leave ──────────────────────────────────────────────────────
  static const String leavesEndpoint            = '/api/v1/leaves';
  static const String leaveStatsEndpoint        = '/api/v1/leaves/stats';
  static const String leaveTypesEndpoint        = '/api/v1/leave/types';
  static const String leaveRequestsEndpoint     = '/api/v1/leave/requests';
  static const String leaveCarryForwardEndpoint = '/api/v1/leave/carry-forward';
  static const String leaveEncashmentsEndpoint  = '/api/v1/leave/encashments';
  static const String leaveAccrueEndpoint       = '/api/v1/leave/balances/accrue';
  static String leaveStatusEndpoint(String id)            => '/api/v1/leaves/$id/status';
  static String leaveApproveEndpoint(String id)           => '/api/v1/leave/requests/$id/approve';
  static String leaveApprovalsEndpoint(String id)         => '/api/v1/leave/requests/$id/approvals';
  static String leaveBalanceByEmployeeEndpoint(String id) => '/api/v1/leave/balances/$id';
  static String leaveTypeEndpoint(String id)              => '/api/v1/leave/types/$id';
  static String encashmentEndpoint(String id)             => '/api/v1/leave/encashments/$id';

  // ── Attendance ────────────────────────────────────────────────
  static const String attendanceEndpoint = '/api/v1/attendance/';
  static const String checkInEndpoint    = '/api/v1/attendance/check-in';
  static const String checkOutEndpoint   = '/api/v1/attendance/check-out';

  // ── Payroll ───────────────────────────────────────────────────
  static const String payrollEndpoint            = '/api/v1/payroll/';
  static const String payrollStatsEndpoint       = '/api/v1/payroll/stats/summary';
  static const String payrollStructuresEndpoint  = '/api/v1/payroll/structures';
  static const String payrollTaxBracketsEndpoint = '/api/v1/payroll/tax-brackets';
  static const String payrollGenerateEndpoint    = '/api/v1/payroll/generate';
  static const String payrollBankFileEndpoint    = '/api/v1/payroll/bank-file';
  static String payrollByIdEndpoint(int id)          => '/api/v1/payroll/$id';
  static String payrollStatusEndpoint(int id)        => '/api/v1/payroll/$id/status';
  static String payslipEndpoint(int id)              => '/api/v1/payroll/$id/payslip';
  static String payslipPdfEndpoint(int id)           => '/api/v1/payroll/$id/payslip/pdf';
  static String payrollStructureEndpoint(String id)  => '/api/v1/payroll/structures/$id';
  static String gratuityEndpoint(String empId)       => '/api/v1/payroll/gratuity/$empId';

  // ── Performance ───────────────────────────────────────────────
  static const String performanceEndpoint = '/api/v1/performance/';
  static const String goalsEndpoint       = '/api/v1/performance/goals';
  static const String reviews360Endpoint  = '/api/v1/performance/reviews360';
  static const String pipsEndpoint        = '/api/v1/performance/pips';
  static String performanceByIdEndpoint(String id)        => '/api/v1/performance/$id';
  static String performanceByEmployeeEndpoint(String id)  => '/api/v1/performance/employee/$id';
  static String goalByIdEndpoint(String id)               => '/api/v1/performance/goals/$id';
  static String goalProgressEndpoint(String id)           => '/api/v1/performance/goals/$id/progress';
  static String review360ByIdEndpoint(String id)          => '/api/v1/performance/reviews360/$id';
  static String pipByIdEndpoint(String id)                => '/api/v1/performance/pips/$id';
  static String pipMilestonesEndpoint(String pipId)       => '/api/v1/performance/pips/$pipId/milestones';
  static String pipMilestoneEndpoint(String p, String m)  => '/api/v1/performance/pips/$p/milestones/$m';

  // ── Recruitment ───────────────────────────────────────────────
  static const String jobsEndpoint       = '/api/v1/recruitment/jobs';
  static const String jobsPublicEndpoint = '/api/v1/recruitment/jobs/public';
  static const String candidatesEndpoint = '/api/v1/recruitment/candidates';
  static const String interviewsEndpoint = '/api/v1/recruitment/interviews';
  static const String offersEndpoint     = '/api/v1/recruitment/offers';
  static String jobByIdEndpoint(String id)           => '/api/v1/recruitment/jobs/$id';
  static String jobApplyEndpoint(String id)          => '/api/v1/recruitment/jobs/$id/apply';
  static String jobCandidatesEndpoint(String id)     => '/api/v1/recruitment/jobs/$id/candidates';
  static String jobPipelineEndpoint(String id)       => '/api/v1/recruitment/jobs/$id/pipeline';
  static String candidateByIdEndpoint(String id)     => '/api/v1/recruitment/candidates/$id';
  static String candidateStageEndpoint(String id)    => '/api/v1/recruitment/candidates/$id/stage';
  static String interviewByIdEndpoint(String id)     => '/api/v1/recruitment/interviews/$id';
  static String interviewFeedbackEndpoint(String id) => '/api/v1/recruitment/interviews/$id/feedback';
  static String offerByIdEndpoint(String id)         => '/api/v1/recruitment/offers/$id';

  // ── Notifications ─────────────────────────────────────────────
  static const String notificationsEndpoint = '/api/v1/notifications/';
  static const String unreadCountEndpoint   = '/api/v1/notifications/unread-count';
  static const String markAllReadEndpoint   = '/api/v1/notifications/mark-all-read';
  static const String announcementsEndpoint = '/api/v1/notifications/announcements';
  static String notificationReadEndpoint(String id)   => '/api/v1/notifications/$id/read';
  static String notificationDeleteEndpoint(String id) => '/api/v1/notifications/$id';
  static String announcementByIdEndpoint(String id)   => '/api/v1/notifications/announcements/$id';

  // ── Reports ───────────────────────────────────────────────────
  static const String reportHeadcountEndpoint       = '/api/v1/reports/headcount';
  static const String reportHeadcountExportEndpoint = '/api/v1/reports/headcount/export';
  static const String reportTurnoverEndpoint        = '/api/v1/reports/turnover';
  static const String reportAttendanceEndpoint      = '/api/v1/reports/attendance';
  static const String reportAttendanceExportEndpoint = '/api/v1/reports/attendance/export';
  static const String reportPayrollEndpoint         = '/api/v1/reports/payroll';
  static const String reportPayrollExportEndpoint   = '/api/v1/reports/payroll/export';
  static const String reportLeaveEndpoint           = '/api/v1/reports/leave';
  static const String reportCustomEndpoint          = '/api/v1/reports/custom';

  // ── Admin ─────────────────────────────────────────────────────
  static const String auditLogsEndpoint        = '/api/v1/admin/audit-logs';
  static const String auditLogsExportEndpoint  = '/api/v1/admin/audit-logs/export';
  static const String companiesEndpoint        = '/api/v1/admin/companies';
  static const String branchesEndpoint         = '/api/v1/admin/branches';
  static const String adminStatsEndpoint       = '/api/v1/admin/stats';
  static String auditTrailEndpoint(String type, String id) => '/api/v1/admin/audit-logs/$type/$id';
  static String companyByIdEndpoint(String id)             => '/api/v1/admin/companies/$id';
  static String companyBranchesEndpoint(String id)         => '/api/v1/admin/companies/$id/branches';
  static String branchByIdEndpoint(String id)              => '/api/v1/admin/branches/$id';

  // ── Secure Storage Keys ───────────────────────────────────────
  static const String tokenKey        = 'jwt_token';
  static const String refreshTokenKey = 'refresh_token';

  // ── Theme ─────────────────────────────────────────────────────
  static const Color primaryColor    = Color(0xFF2563EB);
  static const Color successColor    = Color(0xFF16A34A);
  static const Color errorColor      = Color(0xFFDC2626);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const double defaultPadding = 16.0;

  // ── App Metadata ──────────────────────────────────────────────
  static const String kAppName    = 'HR System Pro';
  static const String kAppVersion = '2.0.0';
  static const String kAppBuild   = '200';
}
