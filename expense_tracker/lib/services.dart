import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

// ==================== AUTHENTICATION SERVICE ====================
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID
  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<User?> signUp(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Create user document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'userId': user.uid,
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Create default categories for new user
        await _createDefaultCategories(user.uid);

        // Create default payment methods for new user
        await _createDefaultPaymentMethods(user.uid);
      }

      return user;
    } catch (e) {
      print('Error in signUp: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Error in signIn: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error in signOut: $e');
      rethrow;
    }
  }

  // Create default categories for new users
  Future<void> _createDefaultCategories(String userId) async {
    final defaultCategories = [
      {'name': 'Food', 'iconName': 'restaurant', 'colorHex': 'orange'},
      {'name': 'Transport', 'iconName': 'car', 'colorHex': 'blue'},
      {'name': 'Bills', 'iconName': 'receipt', 'colorHex': 'yellow'},
      {'name': 'Entertainment', 'iconName': 'movie', 'colorHex': 'red'},
      {'name': 'Shopping', 'iconName': 'shopping', 'colorHex': 'purple'},
      {'name': 'Health', 'iconName': 'hospital', 'colorHex': 'green'},
      {'name': 'Other', 'iconName': 'more', 'colorHex': 'grey'},
    ];

    for (var category in defaultCategories) {
      await _firestore.collection('categories').add({
        'userId': userId,
        'name': category['name'],
        'iconName': category['iconName'],
        'colorHex': category['colorHex'],
      });
    }
  }

  // Create default payment methods for new users
  Future<void> _createDefaultPaymentMethods(String userId) async {
    final defaultMethods = [
      {'type': 'Cash', 'details': 'Cash payment'},
      {'type': 'Credit Card', 'details': 'Credit card payment'},
      {'type': 'Debit Card', 'details': 'Debit card payment'},
    ];

    for (var method in defaultMethods) {
      await _firestore.collection('paymentMethods').add({
        'userId': userId,
        'type': method['type'],
        'details': method['details'],
      });
    }
  }

  // Get user data
  Future<UserModel?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
}

// ==================== EXPENSE SERVICE ====================
class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add expense
  Future<void> addExpense(Expense expense) async {
    try {
      await _firestore.collection('expenses').add(expense.toMap());
    } catch (e) {
      print('Error adding expense: $e');
      rethrow;
    }
  }

  // Update expense
  Future<void> updateExpense(Expense expense) async {
    try {
      if (expense.expenseId != null) {
        await _firestore
            .collection('expenses')
            .doc(expense.expenseId)
            .update(expense.toMap());
      }
    } catch (e) {
      print('Error updating expense: $e');
      rethrow;
    }
  }

  // Delete expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _firestore.collection('expenses').doc(expenseId).delete();
    } catch (e) {
      print('Error deleting expense: $e');
      rethrow;
    }
  }

  // Get user expenses stream
  Stream<List<Expense>> getUserExpenses(String userId) {
    return _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Expense.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // Get expenses for a specific month
  Stream<List<Expense>> getMonthlyExpenses(String userId, DateTime month) {
    DateTime startOfMonth = DateTime(month.year, month.month, 1);
    DateTime endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Expense.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // Get total expenses for user
  Future<double> getTotalExpenses(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data() as Map<String, dynamic>)['amount'] ?? 0;
      }
      return total;
    } catch (e) {
      print('Error getting total expenses: $e');
      return 0;
    }
  }
}

// ==================== CATEGORY SERVICE ====================
class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add category
  Future<void> addCategory(Category category) async {
    try {
      await _firestore.collection('categories').add(category.toMap());
    } catch (e) {
      print('Error adding category: $e');
      rethrow;
    }
  }

  // Update category
  Future<void> updateCategory(Category category) async {
    try {
      if (category.categoryId != null) {
        await _firestore
            .collection('categories')
            .doc(category.categoryId)
            .update(category.toMap());
      }
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('categories').doc(categoryId).delete();
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }

  // Get user categories stream
  Stream<List<Category>> getUserCategories(String userId) {
    return _firestore
        .collection('categories')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Category.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // Get category by ID
  Future<Category?> getCategoryById(String categoryId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('categories')
          .doc(categoryId)
          .get();
      if (doc.exists) {
        return Category.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting category: $e');
      return null;
    }
  }
}

// ==================== PAYMENT METHOD SERVICE ====================
class PaymentMethodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add payment method
  Future<void> addPaymentMethod(PaymentMethod method) async {
    try {
      await _firestore.collection('paymentMethods').add(method.toMap());
    } catch (e) {
      print('Error adding payment method: $e');
      rethrow;
    }
  }

  // Update payment method
  Future<void> updatePaymentMethod(PaymentMethod method) async {
    try {
      if (method.methodId != null) {
        await _firestore
            .collection('paymentMethods')
            .doc(method.methodId)
            .update(method.toMap());
      }
    } catch (e) {
      print('Error updating payment method: $e');
      rethrow;
    }
  }

  // Delete payment method
  Future<void> deletePaymentMethod(String methodId) async {
    try {
      await _firestore.collection('paymentMethods').doc(methodId).delete();
    } catch (e) {
      print('Error deleting payment method: $e');
      rethrow;
    }
  }

  // Get user payment methods stream
  Stream<List<PaymentMethod>> getUserPaymentMethods(String userId) {
    return _firestore
        .collection('paymentMethods')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PaymentMethod.fromMap(doc.id, doc.data()))
              .toList();
        });
  }
}

// ==================== BUDGET SERVICE ====================
class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add budget
  Future<void> addBudget(Budget budget) async {
    try {
      await _firestore.collection('budgets').add(budget.toMap());
    } catch (e) {
      print('Error adding budget: $e');
      rethrow;
    }
  }

  // Update budget
  Future<void> updateBudget(Budget budget) async {
    try {
      if (budget.budgetId != null) {
        await _firestore
            .collection('budgets')
            .doc(budget.budgetId)
            .update(budget.toMap());
      }
    } catch (e) {
      print('Error updating budget: $e');
      rethrow;
    }
  }

  // Delete budget
  Future<void> deleteBudget(String budgetId) async {
    try {
      await _firestore.collection('budgets').doc(budgetId).delete();
    } catch (e) {
      print('Error deleting budget: $e');
      rethrow;
    }
  }

  // Get user budgets stream
  Stream<List<Budget>> getUserBudgets(String userId) {
    return _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Budget.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // Get current month budget
  Future<Budget?> getCurrentMonthBudget(String userId) async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime endOfMonth = DateTime(now.year, now.month + 1, 0);

      QuerySnapshot snapshot = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .where('categoryId', isNull: true) // Overall budget
          .where(
            'startDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth),
          )
          .where(
            'endDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Budget.fromMap(
          snapshot.docs.first.id,
          snapshot.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('Error getting current month budget: $e');
      return null;
    }
  }

  // Check if budget exists for period
  Future<bool> checkBudgetRemaining(
    String userId,
    String? categoryId,
    double amount,
  ) async {
    try {
      DateTime now = DateTime.now();
      QuerySnapshot budgetSnapshot = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .where('categoryId', isEqualTo: categoryId)
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      if (budgetSnapshot.docs.isEmpty) return true;

      Budget budget = Budget.fromMap(
        budgetSnapshot.docs.first.id,
        budgetSnapshot.docs.first.data() as Map<String, dynamic>,
      );

      // Get total expenses for this budget period
      QuerySnapshot expenseSnapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(budget.startDate),
          )
          .where(
            'date',
            isLessThanOrEqualTo: Timestamp.fromDate(budget.endDate),
          )
          .get();

      double totalSpent = 0;
      for (var doc in expenseSnapshot.docs) {
        if (categoryId == null ||
            (doc.data() as Map<String, dynamic>)['categoryId'] == categoryId) {
          totalSpent += (doc.data() as Map<String, dynamic>)['amount'] ?? 0;
        }
      }

      return (totalSpent + amount) <= budget.limitAmount;
    } catch (e) {
      print('Error checking budget: $e');
      return true;
    }
  }
}
