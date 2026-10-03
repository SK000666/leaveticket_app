
class LeaveApplication {
  final String id;
  final String employeeName;
  final String employeeId;
  final String designation;
  final String email;
  final DateTime joiningDate;
  final int balanceLeaveDays;
  final DateTime visaExpiryDate;
  final DateTime passportExpiryDate;
  final DateTime fromDate;
  final DateTime toDate;
  final int totalDays;
  final bool ticketEligible;
  final DateTime? flightDate;
  final String? origin;
  final String? destination;
  final String leaveType;
  final String? remarks;
  final String status;
  final DateTime? createdAt;

  const LeaveApplication({
    required this.id,
    required this.employeeName,
    required this.employeeId,
    required this.designation,
    required this.email,
    required this.joiningDate,
    required this.balanceLeaveDays,
    required this.visaExpiryDate,
    required this.passportExpiryDate,
    required this.fromDate,
    required this.toDate,
    required this.totalDays,
    required this.ticketEligible,
    this.flightDate,
    this.origin,
    this.destination,
    required this.leaveType,
    this.remarks,
    required this.status,
    this.createdAt,
  });

  factory LeaveApplication.fromMap(Map<String, dynamic> map) {
    return LeaveApplication(
      id: map['id'].toString(),
      employeeName: map['employee_name'] as String? ?? '',
      employeeId: map['employee_id'] as String? ?? '',
      designation: map['designation'] as String? ?? '',
      email: map['email'] as String? ?? '',
      joiningDate: DateTime.parse(map['joining_date'] as String),
      balanceLeaveDays:
          (map['balance_leave_days'] as num?)?.toInt() ?? 0,
      visaExpiryDate:
          DateTime.parse(map['visa_expiry_date'] as String),
      passportExpiryDate:
          DateTime.parse(map['passport_expiry_date'] as String),
      fromDate: DateTime.parse(map['from_date'] as String),
      toDate: DateTime.parse(map['to_date'] as String),
      totalDays: (map['total_days'] as num).toInt(),
      ticketEligible: map['ticket_eligible'] as bool? ?? false,
      flightDate: map['flight_date'] == null
          ? null
          : DateTime.parse(map['flight_date'] as String),
      origin: map['origin'] as String?,
      destination: map['destination'] as String?,
      leaveType: map['leave_type'] as String? ?? '',
      remarks: map['remarks'] as String?,
      status: map['status'] as String? ?? 'Pending',
      createdAt: map['created_at'] == null
          ? null
          : DateTime.parse(map['created_at'] as String),
    );
  }
}