import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';

class RecurringPayment {
  final String id;
  final String name;
  final String type; // 'income' or 'expense'
  final String category;
  final double amount;
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime startDate;
  final int? numberOfPayments; // null for unlimited
  final String? accountId;
  final String note;

  RecurringPayment({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.amount,
    required this.frequency,
    required this.startDate,
    this.numberOfPayments,
    this.accountId,
    this.note = '',
  });

  // Convert to map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'category': category,
      'amount': amount,
      'frequency': frequency,
      'start_date': startDate.toUtc().toIso8601String(),
      'account_id': accountId,
      'number_of_payments': numberOfPayments,
      'note': note,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  // Create from map
  factory RecurringPayment.fromMap(Map<String, dynamic> map) {
    return RecurringPayment(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      frequency: map['frequency'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      accountId: map['account_id'] as String?,
      numberOfPayments: map['number_of_payments'] as int?,
      note: map['note'] as String? ?? '',
    );
  }

  // Get next occurrence date from a given date
  DateTime getNextOccurrence(DateTime from) {
    DateTime next = startDate;

    while (next.isBefore(from)) {
      switch (frequency) {
        case 'daily':
          next = DateTime(next.year, next.month, next.day + 1);
          break;
        case 'weekly':
          next = DateTime(next.year, next.month, next.day + 7);
          break;
        case 'monthly':
          next = DateTime(next.year, next.month + 1, next.day);
          break;
        case 'yearly':
          next = DateTime(next.year + 1, next.month, next.day);
          break;
      }
    }

    return next;
  }

  // Check if this payment should occur on a given date
  bool occursOn(DateTime date) {
    // Normalize both dates to compare only year, month, day
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStartDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    if (normalizedDate.isBefore(normalizedStartDate)) return false;

    DateTime checkDate = normalizedStartDate;
    int occurrenceCount =
        1; // Start at 1 since checkDate starts at the first occurrence

    while (checkDate.isBefore(date) || _isSameDay(checkDate, date)) {
      if (_isSameDay(checkDate, date)) {
        // Check if we've exceeded the number of payments
        if (numberOfPayments != null && occurrenceCount > numberOfPayments!) {
          return false;
        }
        return true;
      }

      occurrenceCount++;
      if (numberOfPayments != null && occurrenceCount > numberOfPayments!) {
        return false;
      }

      switch (frequency) {
        case 'daily':
          checkDate = DateTime(
            checkDate.year,
            checkDate.month,
            checkDate.day + 1,
          );
          break;
        case 'weekly':
          checkDate = DateTime(
            checkDate.year,
            checkDate.month,
            checkDate.day + 7,
          );
          break;
        case 'monthly':
          checkDate = DateTime(
            checkDate.year,
            checkDate.month + 1,
            checkDate.day,
          );
          break;
        case 'yearly':
          checkDate = DateTime(
            checkDate.year + 1,
            checkDate.month,
            checkDate.day,
          );
          break;
      }
    }

    return false;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class RecurringPaymentProvider with ChangeNotifier {
  final List<RecurringPayment> _payments = [];
  bool _isLoaded = false;
  List<RecurringPayment> get payments => _payments;

  // Load recurring payments from database
  Future<void> loadPayments() async {
    if (_isLoaded) return;

    final paymentMaps = await DatabaseHelper.instance.getAllRecurringPayments();
    _payments.clear();

    for (var map in paymentMaps) {
      _payments.add(RecurringPayment.fromMap(map));
    }

    _isLoaded = true;
    notifyListeners();
  }

  void addPayment(RecurringPayment payment) async {
    _payments.add(payment);
    notifyListeners();

    // Save to database
    await DatabaseHelper.instance.insertRecurringPayment(payment.toMap());

    // Process recurring payments immediately to create first transaction if due
    await DatabaseHelper.instance.processRecurringPayments();
  }

  void updatePayment(RecurringPayment payment) async {
    final index = _payments.indexWhere((p) => p.id == payment.id);
    if (index != -1) {
      _payments[index] = payment;
      notifyListeners();

      // Update in database
      await DatabaseHelper.instance.insertRecurringPayment(payment.toMap());

      // Process recurring payments after update
      await DatabaseHelper.instance.processRecurringPayments();
    }
  }

  void removePayment(String id) async {
    _payments.removeWhere((p) => p.id == id);
    notifyListeners();

    // Delete from database
    await DatabaseHelper.instance.deleteRecurringPayment(id);
  }

  // Get all recurring payments that occur on a specific date
  List<RecurringPayment> getPaymentsForDate(DateTime date) {
    return _payments.where((payment) => payment.occursOn(date)).toList();
  }

  // Get all recurring payments in a date range
  List<RecurringPayment> getPaymentsInRange(DateTime start, DateTime end) {
    final List<RecurringPayment> result = [];

    for (var payment in _payments) {
      DateTime checkDate = payment.startDate;
      if (checkDate.isAfter(end)) continue;

      int occurrenceCount = 0;

      while (checkDate.isBefore(end) || checkDate.isAtSameMomentAs(end)) {
        if ((checkDate.isAfter(start) || checkDate.isAtSameMomentAs(start)) &&
            (checkDate.isBefore(end) || checkDate.isAtSameMomentAs(end))) {
          if (payment.numberOfPayments == null ||
              occurrenceCount < payment.numberOfPayments!) {
            result.add(payment);
          }
        }

        occurrenceCount++;
        if (payment.numberOfPayments != null &&
            occurrenceCount >= payment.numberOfPayments!) {
          break;
        }

        switch (payment.frequency) {
          case 'daily':
            checkDate = DateTime(
              checkDate.year,
              checkDate.month,
              checkDate.day + 1,
            );
            break;
          case 'weekly':
            checkDate = DateTime(
              checkDate.year,
              checkDate.month,
              checkDate.day + 7,
            );
            break;
          case 'monthly':
            checkDate = DateTime(
              checkDate.year,
              checkDate.month + 1,
              checkDate.day,
            );
            break;
          case 'yearly':
            checkDate = DateTime(
              checkDate.year + 1,
              checkDate.month,
              checkDate.day,
            );
            break;
        }
      }
    }

    return result;
  }
}
