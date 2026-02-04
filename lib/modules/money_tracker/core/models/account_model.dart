// lib/core/models/account_model.dart
class Account {
  final String id;
  final String name;
  final String accountType;
  final String currency;
  final double initialBalance;
  final double currentBalance;
  final String iconName;
  final String note;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Account({
    String? id,
    required this.name,
    required this.accountType,
    required this.currency,
    required this.initialBalance,
    double? currentBalance,
    required this.iconName,
    this.note = '',
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) :
        id = id ?? _generateId(),
        currentBalance = currentBalance ?? initialBalance,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    _validate();
  }

  // ADDED: Getter for backward compatibility
  String get type => accountType;
  double get amount => currentBalance;

  static String _generateId() {
    return 'acc_${DateTime.now().millisecondsSinceEpoch}';
  }

  void _validate() {
    if (name.trim().isEmpty) throw ArgumentError('Account name cannot be empty');
    if (initialBalance < 0) throw ArgumentError('Initial balance cannot be negative');
    if (accountType.trim().isEmpty) throw ArgumentError('Account type cannot be empty');
    if (currency.trim().isEmpty) throw ArgumentError('Currency cannot be empty');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name.trim(),
      'account_type': accountType,
      'currency': currency,
      'initial_balance': initialBalance,
      'current_balance': currentBalance,
      'icon_name': iconName,
      'note': note.trim(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'] ?? '',
      accountType: map['account_type'] ?? '',
      currency: map['currency'] ?? '',
      initialBalance: _parseDouble(map['initial_balance']),
      currentBalance: _parseDouble(map['current_balance']),
      iconName: map['icon_name'] ?? 'cash',
      note: map['note'] ?? '',
      isActive: (map['is_active'] ?? 1) == 1,
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

  Account copyWith({
    String? name,
    String? accountType,
    String? currency,
    double? initialBalance,
    double? currentBalance,
    String? iconName,
    String? note,
    bool? isActive,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      currency: currency ?? this.currency,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      iconName: iconName ?? this.iconName,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}