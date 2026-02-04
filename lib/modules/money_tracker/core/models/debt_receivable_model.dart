// lib/core/models/debt_receivable_model.dart
import 'package:flutter/material.dart';

class DebtReceivable {
  final String id;
  final String type; // 'debt' or 'receivable'
  final String personName; // Who owes or is owed
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final String? linkedAccountId; // The actual account money came from/to
  final String? linkedTransactionId; // The transaction that created this
  final bool isSettled;
  final DateTime createdAt;
  final DateTime updatedAt;

  DebtReceivable({
    String? id,
    required this.type,
    required this.personName,
    required this.amount,
    required this.category,
    this.note = '',
    DateTime? date,
    this.linkedAccountId,
    this.linkedTransactionId,
    this.isSettled = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _generateId(),
        date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    _validate();
  }

  static String _generateId() {
    return 'dr_${DateTime.now().millisecondsSinceEpoch}';
  }

  void _validate() {
    if (amount <= 0) throw ArgumentError('Amount must be positive');
    if (personName.trim().isEmpty) {
      throw ArgumentError('Person name cannot be empty');
    }
    if (!['debt', 'receivable'].contains(type.toLowerCase())) {
      throw ArgumentError('Type must be either "debt" or "receivable"');
    }
  }

  // Get icon based on type
  IconData get typeIcon {
    return type == 'debt' ? Icons.arrow_upward : Icons.arrow_downward;
  }

  // Get color based on type
  Color get typeColor {
    return type == 'debt' ? Colors.red : Colors.green;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toLowerCase(),
      'person_name': personName.trim(),
      'amount': amount,
      'category': category,
      'note': note.trim(),
      'linked_account_id': linkedAccountId,
      'linked_transaction_id': linkedTransactionId,
      'is_settled': isSettled ? 1 : 0,
      'transaction_date': date.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory DebtReceivable.fromMap(Map<String, dynamic> map) {
    return DebtReceivable(
      id: map['id'],
      type: map['type'] ?? 'debt',
      personName: map['person_name'] ?? '',
      amount: _parseDouble(map['amount']),
      category: map['category'] ?? '',
      note: map['note'] ?? '',
      linkedAccountId: map['linked_account_id'] as String?,
      linkedTransactionId: map['linked_transaction_id'] as String?,
      isSettled: (map['is_settled'] ?? 0) == 1,
      date: DateTime.parse(map['transaction_date']).toLocal(),
      createdAt: DateTime.parse(map['created_at']).toLocal(),
      updatedAt: DateTime.parse(map['updated_at']).toLocal(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  DebtReceivable copyWith({
    String? personName,
    double? amount,
    String? category,
    String? note,
    DateTime? date,
    bool? isSettled,
  }) {
    return DebtReceivable(
      id: id,
      type: type,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      linkedAccountId: linkedAccountId,
      linkedTransactionId: linkedTransactionId,
      isSettled: isSettled ?? this.isSettled,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
