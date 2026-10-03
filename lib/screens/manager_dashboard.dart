
import 'package:flutter/material.dart';

import '../models/leave_application.dart';
import '../services/auth_service.dart';
import '../services/leave_service.dart';
import 'leave_form_screen.dart';
import 'login_screen.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  final _leaveService = LeaveService.instance;

  late Future<List<LeaveApplication>> _applicationsFuture;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  void _loadApplications() {
    _applicationsFuture = _leaveService.getMyApplications();
  }

  Future<void> _refreshApplications() async {
    setState(_loadApplications);
    await _applicationsFuture;
  }

  Future<void> _openLeaveForm() async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const LeaveFormScreen(),
      ),
    );

    if (submitted == true && mounted) {
      setState(_loadApplications);
    }
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

  Widget _summaryCard(String title, int count, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 28, color: Colors.indigo),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _applicationCard(LeaveApplication application) {
    final color = _statusColor(application.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    application.employeeName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(application.status),
                  backgroundColor: color.withValues(alpha: 0.12),
                  labelStyle: TextStyle(color: color),
                ),
              ],
            ),
            Text('Employee ID: ${application.employeeId}'),
            const SizedBox(height: 6),
            Text('Leave type: ${application.leaveType}'),
            Text('From: ${application.fromDate.toLocal().toString().split(' ')[0]}'),
            Text('To: ${application.toDate.toLocal().toString().split(' ')[0]}'),
            Text('Total days: ${application.totalDays}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard!!'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshApplications,
        child: FutureBuilder<List<LeaveApplication>>(
          future: _applicationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  Text('Could not load applications: ${snapshot.error}'),
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(_loadApplications);
                      },
                      child: const Text('Try again'),
                    ),
                  ),
                ],
              );
            }

            final applications = snapshot.data ?? [];
            final pendingCount = applications
                .where((application) => application.status == 'Pending')
                .length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Welcome!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    _summaryCard(
                      'Total Applications',
                      applications.length,
                      Icons.description_outlined,
                    ),
                    _summaryCard(
                      'Pending',
                      pendingCount,
                      Icons.pending_actions,
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Text(
                  'My Leave Applications',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),

                if (applications.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text('No leave applications yet.'),
                      ],
                    ),
                  )
                else
                  ...applications.map(_applicationCard),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openLeaveForm,
        icon: const Icon(Icons.add),
        label: const Text('New Application'),
      ),
    );
  }
}