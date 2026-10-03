
import 'package:flutter/material.dart';

import '../models/leave_application.dart';
import '../services/auth_service.dart';
import '../services/leave_service.dart';
import 'login_screen.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final LeaveService _service = LeaveService.instance;

  late Future<List<LeaveApplication>> _applicationsFuture;

  String _filter = 'All';
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  void _loadApplications() {
    _applicationsFuture = _service.getAllApplications();
  }

  Future<void> _refresh() async {
    setState(_loadApplications);
    await _applicationsFuture;
  }

  Future<void> _logout() async {
    await AuthService().logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _date(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? 'Not provided' : value)),
        ],
      ),
    );
  }

  Future<void> _showReview(LeaveApplication application) async {
    final decision = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Review Application'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal Details',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _detail('Employee ID', application.employeeId),
                _detail('Employee Name', application.employeeName),
                _detail('Designation', application.designation),
                _detail('Email', application.email),
                _detail('Joining Date', _date(application.joiningDate)),
                _detail(
                  'Balance Leave Days',
                  '${application.balanceLeaveDays}',
                ),
                _detail('Visa Expiry', _date(application.visaExpiryDate)),
                _detail(
                  'Passport Expiry',
                  _date(application.passportExpiryDate),
                ),
                const Divider(),
                const Text(
                  'Leave Details',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _detail('Leave Type', application.leaveType),
                _detail('From Date', _date(application.fromDate)),
                _detail('To Date', _date(application.toDate)),
                _detail('Total Days', '${application.totalDays}'),
                const Divider(),
                const Text(
                  'Ticket Details',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _detail(
                  'Ticket Eligible',
                  application.ticketEligible ? 'Yes' : 'No',
                ),
                if (application.ticketEligible) ...[
                  if (application.flightDate != null)
                    _detail('Flight Date', _date(application.flightDate!)),
                  _detail('Origin', application.origin ?? ''),
                  _detail('Destination', application.destination ?? ''),
                ],
                _detail('Remarks', application.remarks ?? ''),
                _detail('Status', application.status),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            if (application.status == 'Pending') ...[
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, 'Rejected'),
                child: const Text(
                  'Reject',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, 'Approved'),
                child: const Text('Approve'),
              ),
            ],
          ],
        );
      },
    );

    if (decision != null && mounted) {
      await _decide(application, decision);
    }
  }

  Future<void> _decide(
    LeaveApplication application,
    String decision,
  ) async {
    setState(() => _processing = true);

    try {
      await _service.decideApplication(
        applicationId: application.id,
        decision: decision,
      );

      if (!mounted) return;

      setState(_loadApplications);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Application $decision successfully.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update application: $error')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Widget _applicationCard(LeaveApplication application) {
    final color = _statusColor(application.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          application.employeeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'ID: ${application.employeeId}\n'
            '${application.leaveType} leave • ${application.totalDays} day(s)\n'
            '${_date(application.fromDate)} – ${_date(application.toDate)}',
          ),
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.circle, size: 12, color: color),
            const SizedBox(height: 4),
            Text(
              application.status,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
        onTap: () => _showReview(application),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<List<LeaveApplication>>(
        future: _applicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Could not load applications: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => setState(_loadApplications),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final applications = snapshot.data ?? [];
          final pending = applications
              .where((a) => a.status == 'Pending')
              .length;
          final approved = applications
              .where((a) => a.status == 'Approved')
              .length;
          final rejected = applications
              .where((a) => a.status == 'Rejected')
              .length;

          final filtered = _filter == 'All'
              ? applications
              : applications
                  .where((a) => a.status == _filter)
                  .toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Applications Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _summaryChip('Total', applications.length),
                    _summaryChip('Pending', pending),
                    _summaryChip('Approved', approved),
                    _summaryChip('Rejected', rejected),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Review Applications',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: ['All', 'Pending', 'Approved', 'Rejected']
                      .map(
                        (status) => ChoiceChip(
                          label: Text(status),
                          selected: _filter == status,
                          onSelected: (_) {
                            setState(() => _filter = status);
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                if (_processing) const LinearProgressIndicator(),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No applications in this category.'),
                    ),
                  )
                else
                  ...filtered.map(_applicationCard),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryChip(String label, int count) {
    return Chip(label: Text('$label: $count'));
  }
}