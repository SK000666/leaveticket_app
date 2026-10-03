
import 'package:flutter/material.dart';

import '../services/leave_service.dart';

class LeaveFormScreen extends StatefulWidget {
  const LeaveFormScreen({super.key});

  @override
  State<LeaveFormScreen> createState() => _LeaveFormScreenState();
}

class _LeaveFormScreenState extends State<LeaveFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _employeeId = TextEditingController();
  final _employeeName = TextEditingController();
  final _designation = TextEditingController();
  final _email = TextEditingController();
  final _balanceDays = TextEditingController();
  final _origin = TextEditingController();
  final _destination = TextEditingController();
  final _remarks = TextEditingController();

  DateTime? _joiningDate;
  DateTime? _visaExpiryDate;
  DateTime? _passportExpiryDate;
  DateTime? _fromDate;
  DateTime? _toDate;
  DateTime? _flightDate;

  bool _ticketEligible = false;
  bool _loading = false;

  String _leaveType = 'Annual';

  int get _totalDays {
    if (_fromDate == null || _toDate == null) {
      return 0;
    }

    return _toDate!.difference(_fromDate!).inDays + 1;
  }

  @override
  void dispose() {
    _employeeId.dispose();
    _employeeName.dispose();
    _designation.dispose();
    _email.dispose();
    _balanceDays.dispose();
    _origin.dispose();
    _destination.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _selectDate(String field) async {
    final now = DateTime.now();

    DateTime? currentDate;

    switch (field) {
      case 'joining':
        currentDate = _joiningDate;
        break;
      case 'visa':
        currentDate = _visaExpiryDate;
        break;
      case 'passport':
        currentDate = _passportExpiryDate;
        break;
      case 'from':
        currentDate = _fromDate;
        break;
      case 'to':
        currentDate = _toDate;
        break;
      case 'flight':
        currentDate = _flightDate;
        break;
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: currentDate ?? now,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) return;

    setState(() {
      switch (field) {
        case 'joining':
          _joiningDate = selected;
          break;
        case 'visa':
          _visaExpiryDate = selected;
          break;
        case 'passport':
          _passportExpiryDate = selected;
          break;
        case 'from':
          _fromDate = selected;
          break;
        case 'to':
          _toDate = selected;
          break;
        case 'flight':
          _flightDate = selected;
          break;
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String? _validateText(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $label';
    }

    return null;
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: validator ??
            (value) => _validateText(value, label),
      ),
    );
  }

  Widget _dateField(String label, String field, DateTime? date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _selectDate(field),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_month),
          ),
          child: Text(_formatDate(date)),
        ),
      ),
    );
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_joiningDate == null ||
        _visaExpiryDate == null ||
        _passportExpiryDate == null ||
        _fromDate == null ||
        _toDate == null) {
      _showMessage('Please select all required dates.');
      return;
    }

    if (_toDate!.isBefore(_fromDate!)) {
      _showMessage('To Date cannot be before From Date.');
      return;
    }

    final balance = int.tryParse(_balanceDays.text.trim());

    if (balance == null || balance < 0) {
      _showMessage('Enter a valid leave balance.');
      return;
    }

    if (_totalDays > balance) {
      _showMessage('Total leave days exceed the available balance.');
      return;
    }

    if (_joiningDate!.isAfter(_fromDate!)) {
      _showMessage('Leave cannot start before the joining date.');
      return;
    }

    if (_ticketEligible) {
      if (_flightDate == null ||
          _origin.text.trim().isEmpty ||
          _destination.text.trim().isEmpty) {
        _showMessage('Please complete all ticket details.');
        return;
      }
    }

    setState(() => _loading = true);

    try {
      await LeaveService.instance.submitApplication(
        employeeId: _employeeId.text,
        employeeName: _employeeName.text,
        designation: _designation.text,
        email: _email.text,
        joiningDate: _joiningDate!,
        balanceLeaveDays: balance,
        visaExpiryDate: _visaExpiryDate!,
        passportExpiryDate: _passportExpiryDate!,
        fromDate: _fromDate!,
        toDate: _toDate!,
        ticketEligible: _ticketEligible,
        flightDate: _flightDate,
        origin: _origin.text,
        destination: _destination.text,
        leaveType: _leaveType,
        remarks: _remarks.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave application submitted successfully.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      _showMessage('Submission failed: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Application'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionTitle('Personal Details'),

            _textField('Employee ID', _employeeId),
            _textField('Employee Name', _employeeName),
            _textField('Designation', _designation),

            _textField(
              'Email ID',
              _email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter Email ID';
                }

                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                    .hasMatch(value.trim())) {
                  return 'Enter a valid email address';
                }

                return null;
              },
            ),

            _dateField('Joining Date', 'joining', _joiningDate),

            _textField(
              'Balance Leave Days',
              _balanceDays,
              keyboardType: TextInputType.number,
              validator: (value) {
                final days = int.tryParse(value ?? '');

                if (days == null || days < 0) {
                  return 'Enter a valid number of days';
                }

                return null;
              },
            ),

            _dateField(
              'Visa Expiry Date',
              'visa',
              _visaExpiryDate,
            ),

            _dateField(
              'Passport Expiry Date',
              'passport',
              _passportExpiryDate,
            ),

            const Divider(height: 32),

            _sectionTitle('Leave Details'),

            _dateField('From Date', 'from', _fromDate),
            _dateField('To Date', 'to', _toDate),

            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Total Days',
                  border: OutlineInputBorder(),
                ),
                child: Text('$_totalDays day(s)'),
              ),
            ),

            DropdownButtonFormField<String>(
              initialValue: _leaveType,
              decoration: const InputDecoration(
                labelText: 'Leave Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Annual',
                  child: Text('Annual'),
                ),
                DropdownMenuItem(
                  value: 'Emergency',
                  child: Text('Emergency'),
                ),
                DropdownMenuItem(
                  value: 'Medical',
                  child: Text('Medical'),
                ),
                DropdownMenuItem(
                  value: 'Other',
                  child: Text('Other'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _leaveType = value);
                }
              },
            ),

            const Divider(height: 32),

            _sectionTitle('Ticket Details'),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Are you entitled for a ticket?',
              ),
              subtitle: Text(_ticketEligible ? 'Yes' : 'No'),
              value: _ticketEligible,
              onChanged: (value) {
                setState(() {
                  _ticketEligible = value;

                  if (!value) {
                    _flightDate = null;
                    _origin.clear();
                    _destination.clear();
                  }
                });
              },
            ),

            if (_ticketEligible) ...[
              const SizedBox(height: 12),

              _dateField(
                'Flight Date',
                'flight',
                _flightDate,
              ),

              _textField('Origin', _origin),
              _textField('Destination', _destination),
            ],

            TextFormField(
              controller: _remarks,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                hintText: 'Enter any additional information',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _loading ? null : _submitApplication,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _loading ? 'Submitting...' : 'Submit Application',
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}