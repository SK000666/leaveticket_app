
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/leave_application.dart';

class LeaveService {
  LeaveService._();

  static final LeaveService instance = LeaveService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Submit a new leave application.
  Future<void> submitApplication({
    required String employeeId,
    required String employeeName,
    required String designation,
    required String email,
    required DateTime joiningDate,
    required int balanceLeaveDays,
    required DateTime visaExpiryDate,
    required DateTime passportExpiryDate,
    required DateTime fromDate,
    required DateTime toDate,
    required bool ticketEligible,
    DateTime? flightDate,
    String? origin,
    String? destination,
    required String leaveType,
    String? remarks,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Please log in again.');
    }

    if (toDate.isBefore(fromDate)) {
      throw Exception(
        'The end date cannot be before the start date.',
      );
    }

    final totalDays = toDate.difference(fromDate).inDays + 1;

    final response = await _supabase
        .from('leave_applications')
        .insert({
          'manager_id': user.id,
          'employee_id': employeeId.trim(),
          'employee_name': employeeName.trim(),
          'designation': designation.trim(),
          'email': email.trim(),
          'joining_date': _formatDate(joiningDate),
          'balance_leave_days': balanceLeaveDays,
          'visa_expiry_date': _formatDate(visaExpiryDate),
          'passport_expiry_date': _formatDate(passportExpiryDate),
          'from_date': _formatDate(fromDate),
          'to_date': _formatDate(toDate),
          'total_days': totalDays,
          'ticket_eligible': ticketEligible,
          'flight_date': ticketEligible && flightDate != null
              ? _formatDate(flightDate)
              : null,
          'origin': ticketEligible ? origin?.trim() : null,
          'destination': ticketEligible ? destination?.trim() : null,
          'leave_type': leaveType,
          'remarks': remarks?.trim(),
          'status': 'Pending',
        })
        .select('id')
        .single();

    // Notify the owner after the application is saved.
    await _sendEmailNotification(
      type: 'new_application',
      applicationId: response['id'] as String,
    );
  }

  // Fetch applications created by the logged-in manager.
  Future<List<LeaveApplication>> getMyApplications() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Please log in again.');
    }

    final response = await _supabase
        .from('leave_applications')
        .select()
        .eq('manager_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (item) => LeaveApplication.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  // Fetch all applications. Database RLS controls what the user can see.
  Future<List<LeaveApplication>> getAllApplications() async {
    final response = await _supabase
        .from('leave_applications')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (item) => LeaveApplication.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  // Approve or reject an application.
  Future<void> decideApplication({
    required String applicationId,
    required String decision,
  }) async {
    if (decision != 'Approved' && decision != 'Rejected') {
      throw Exception('Invalid decision.');
    }

    // The database function validates the owner's permission
    // and records the decision.
    await _supabase.rpc(
      'decide_leave_application',
      params: {
        'application_id': applicationId,
        'decision': decision,
      },
    );

    // Notify the manager and employee after the decision is saved.
    await _sendEmailNotification(
      type: 'decision',
      applicationId: applicationId,
      decision: decision,
    );
  }

  // Send an email using the Supabase Edge Function.
  Future<void> _sendEmailNotification({
    required String type,
    required String applicationId,
    String? decision,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'send-leave-email',
        body: {
        'type': type,
        'applicationId': applicationId,
        'decision': decision,
      },
      );

      if (response.status < 200 || response.status >= 300) {
        debugPrint(
          'Email notification failed: ${response.data}',
        );
      }
    } catch (e) {
      // Email failure should not undo a successful application
      // or approval/rejection.
      debugPrint('Email notification failed: $e');
    }
  }

  // Format a date for a Supabase DATE column.
  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}