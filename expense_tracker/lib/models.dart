import 'package:cloud_firestore/cloud_firestore.dart';

// ==================== USER MODEL ====================
class UserModel {
  final String userId;
  final String name;
  final String email;

  UserModel({required this.userId, required this.name, required this.email});

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'name': name, 'email': email};
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
    );
  }
}

// ==================== EXPENSE MODEL ====================
class Expense {
  final String? expenseId;
  final String userId;
  final String description;
  final double amount;
  final DateTime date;
  final String categoryId;
  final String paymentMethodId;

  Expense({
    this.expenseId,
    required this.userId,
    required this.description,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.paymentMethodId,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'description': description,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'categoryId': categoryId,
      'paymentMethodId': paymentMethodId,
    };
  }

  factory Expense.fromMap(String id, Map<String, dynamic> map) {
    return Expense(
      expenseId: id,
      userId: map['userId'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      categoryId: map['categoryId'] ?? '',
      paymentMethodId: map['paymentMethodId'] ?? '',
    );
  }
}

// ==================== CATEGORY MODEL ====================
class Category {
  final String? categoryId;
  final String userId;
  final String name;
  final String iconName;
  final String colorHex;

  Category({
    this.categoryId,
    required this.userId,
    required this.name,
    required this.iconName,
    required this.colorHex,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'iconName': iconName,
      'colorHex': colorHex,
    };
  }

  factory Category.fromMap(String id, Map<String, dynamic> map) {
    return Category(
      categoryId: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      iconName: map['iconName'] ?? 'other',
      colorHex: map['colorHex'] ?? 'grey',
    );
  }
}

// ==================== PAYMENT METHOD MODEL ====================
class PaymentMethod {
  final String? methodId;
  final String userId;
  final String type;
  final String details;

  PaymentMethod({
    this.methodId,
    required this.userId,
    required this.type,
    required this.details,
  });

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'type': type, 'details': details};
  }

  factory PaymentMethod.fromMap(String id, Map<String, dynamic> map) {
    return PaymentMethod(
      methodId: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      details: map['details'] ?? '',
    );
  }
}

// ==================== BUDGET MODEL ====================
class Budget {
  final String? budgetId;
  final String userId;
  final double limitAmount;
  final DateTime startDate;
  final DateTime endDate;
  final String? categoryId; // null means overall budget

  Budget({
    this.budgetId,
    required this.userId,
    required this.limitAmount,
    required this.startDate,
    required this.endDate,
    this.categoryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'limitAmount': limitAmount,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'categoryId': categoryId,
    };
  }

  factory Budget.fromMap(String id, Map<String, dynamic> map) {
    return Budget(
      budgetId: id,
      userId: map['userId'] ?? '',
      limitAmount: (map['limitAmount'] ?? 0).toDouble(),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      categoryId: map['categoryId'],
    );
  }
}
