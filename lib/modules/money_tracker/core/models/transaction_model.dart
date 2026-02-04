// lib/core/models/transaction_model.dart
import 'package:flutter/material.dart';
import '../constants/category_constants.dart';

class MoneyTransaction {
  final String id;
  final String accountId;
  final double amount;
  final String category;
  final String note;
  final String type; // 'income' or 'expense'
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? transferId; // Links transfer transactions together
  final String? transferType; // 'transfer_out', 'transfer_in', or null

  MoneyTransaction({
    String? id,
    required this.accountId,
    required this.amount,
    required this.category,
    this.note = '',
    required this.type,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.transferId,
    this.transferType,
  }) :
        id = id ?? _generateId(),
        date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    _validate();
  }

  static String _generateId() {
    return 'txn_${DateTime.now().millisecondsSinceEpoch}';
  }

  void _validate() {
    if (amount <= 0) throw ArgumentError('Amount must be positive');
    if (category.trim().isEmpty) throw ArgumentError('Category cannot be empty');
    if (!['income', 'expense'].contains(type.toLowerCase())) {
      throw ArgumentError('Type must be either "income" or "expense"');
    }
    if (accountId.trim().isEmpty) throw ArgumentError('Account ID cannot be empty');
  }

  // Get icon for category
  IconData get categoryIcon {
    if (type == 'expense') {
      final expenseCategory = CategoryConstants.expenseCategories
          .firstWhere((cat) => cat.label == category, orElse: () => CategoryConstants.expenseCategories.first);
      return expenseCategory.icon;
    } else {
      final incomeCategory = CategoryConstants.incomeCategories
          .firstWhere((cat) => cat.label == category, orElse: () => CategoryConstants.incomeCategories.first);
      return incomeCategory.icon;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'amount': amount,
      'category': category,
      'note': note.trim(),
      'transaction_type': type.toLowerCase(),
      'transaction_date': date.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'transfer_id': transferId,
      'transfer_type': transferType,
    };
  }

  factory MoneyTransaction.fromMap(Map<String, dynamic> map) {
    return MoneyTransaction(
      id: map['id'],
      accountId: map['account_id'],
      amount: _parseDouble(map['amount']),
      category: map['category'] ?? '',
      note: map['note'] ?? '',
      type: map['transaction_type'] ?? 'expense',
      date: DateTime.parse(map['transaction_date']).toLocal(),
      createdAt: DateTime.parse(map['created_at']).toLocal(),
      updatedAt: DateTime.parse(map['updated_at']).toLocal(),
      transferId: map['transfer_id'] as String?,
      transferType: map['transfer_type'] as String?,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  MoneyTransaction copyWith({
    String? accountId,
    double? amount,
    String? category,
    String? note,
    String? type,
    DateTime? date,
    String? transferId,
    String? transferType,
  }) {
    return MoneyTransaction(
      id: id,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      type: type ?? this.type,
      date: date ?? this.date,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      transferId: transferId ?? this.transferId,
      transferType: transferType ?? this.transferType,
    );
  }
}