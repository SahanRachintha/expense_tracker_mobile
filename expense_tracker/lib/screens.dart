import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services.dart';
import 'models.dart';

// ==================== EXPENSE CARD WIDGET ====================
class ExpenseCard extends StatelessWidget {
  final Expense expense;

  const ExpenseCard({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final categoryService = CategoryService();

    return FutureBuilder<Category?>(
      future: categoryService.getCategoryById(expense.categoryId),
      builder: (context, snapshot) {
        final categoryName = snapshot.data?.name ?? 'Unknown';
        final iconName = snapshot.data?.iconName ?? 'other';
        final colorHex = snapshot.data?.colorHex ?? 'grey';

        final icon = _getIconFromName(iconName);
        final color = _getColorFromHex(colorHex);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            title: Text(expense.description),
            subtitle: Text(
              '$categoryName • ${DateFormat('MMM dd, yyyy').format(expense.date)}',
            ),
            trailing: Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconFromName(String name) {
    switch (name) {
      case 'restaurant':
        return Icons.restaurant;
      case 'car':
        return Icons.directions_car;
      case 'receipt':
        return Icons.receipt;
      case 'movie':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'hospital':
        return Icons.local_hospital;
      default:
        return Icons.more_horiz;
    }
  }

  Color _getColorFromHex(String hex) {
    switch (hex) {
      case 'orange':
        return Colors.orange;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      case 'green':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// ==================== EXPENSES SCREEN ====================
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _selectedFilter = 'All';
  final _authService = AuthService();
  final _expenseService = ExpenseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search expenses...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (value) {
                    setState(() {
                      _selectedFilter = value;
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'All', child: Text('All')),
                    const PopupMenuItem(value: 'Today', child: Text('Today')),
                    const PopupMenuItem(
                      value: 'This Week',
                      child: Text('This Week'),
                    ),
                    const PopupMenuItem(
                      value: 'This Month',
                      child: Text('This Month'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Expense>>(
              stream: _expenseService.getUserExpenses(
                _authService.currentUserId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No expenses yet. Add your first expense!'),
                  );
                }

                final expenses = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    return ExpenseCard(expense: expenses[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }
}

// ==================== ADD EXPENSE SCREEN ====================
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _authService = AuthService();
  final _expenseService = ExpenseService();
  final _categoryService = CategoryService();
  final _paymentMethodService = PaymentMethodService();

  String? _selectedCategoryId;
  String? _selectedPaymentMethodId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      if (_selectedPaymentMethodId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a payment method')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final expense = Expense(
          userId: _authService.currentUserId,
          description: _descriptionController.text,
          amount: double.parse(_amountController.text),
          date: _selectedDate,
          categoryId: _selectedCategoryId!,
          paymentMethodId: _selectedPaymentMethodId!,
        );

        await _expenseService.addExpense(expense);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense added successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<Category>>(
                stream: _categoryService.getUserCategories(
                  _authService.currentUserId,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final categories = snapshot.data!;

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category.categoryId,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<PaymentMethod>>(
                stream: _paymentMethodService.getUserPaymentMethods(
                  _authService.currentUserId,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final methods = snapshot.data!;

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedPaymentMethodId,
                    decoration: InputDecoration(
                      labelText: 'Payment Method',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: methods.map((method) {
                      return DropdownMenuItem(
                        value: method.methodId,
                        child: Text(method.type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethodId = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveExpense,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Save Expense',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== BUDGET SCREEN ====================
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final expenseService = ExpenseService();

    return StreamBuilder<List<Expense>>(
      stream: expenseService.getMonthlyExpenses(
        authService.currentUserId,
        DateTime.now(),
      ),
      builder: (context, expenseSnapshot) {
        if (expenseSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final expenses = expenseSnapshot.data ?? [];
        final totalSpent = expenses.fold<double>(
          0,
          (sum, expense) => sum + expense.amount,
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Budget',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '\$3,000.00',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: (totalSpent / 3000).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Spent: \$${totalSpent.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${((totalSpent / 3000) * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Remaining: \$${(3000 - totalSpent).toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spending by Category',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Track your expenses across different categories',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        );
      },
    );
  }
}

// ==================== REPORTS SCREEN ====================
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final expenseService = ExpenseService();

    return StreamBuilder<List<Expense>>(
      stream: expenseService.getMonthlyExpenses(
        authService.currentUserId,
        DateTime.now(),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final expenses = snapshot.data ?? [];
        final totalExpense = expenses.fold<double>(
          0,
          (sum, expense) => sum + expense.amount,
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This Month',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildReportCard(
                      'Total Expenses',
                      '\$${totalExpense.toStringAsFixed(2)}',
                      Colors.red,
                      Icons.trending_down,
                    ),
                    const SizedBox(height: 12),
                    _buildReportCard(
                      'Number of Transactions',
                      '${expenses.length}',
                      Colors.blue,
                      Icons.receipt_long,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (expenses.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No expenses this month'),
                ),
              )
            else
              ...expenses.take(10).map((expense) {
                return ExpenseCard(expense: expense);
              }),
          ],
        );
      },
    );
  }

  Widget _buildReportCard(
    String title,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== CATEGORIES SCREEN ====================
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final categoryService = CategoryService();

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: StreamBuilder<List<Category>>(
        stream: categoryService.getUserCategories(authService.currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No categories yet'));
          }

          final categories = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryItem(context, category, categoryService);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCategoryDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    Category category,
    CategoryService categoryService,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColorFromHex(category.colorHex).withOpacity(0.2),
          child: Icon(
            _getIconFromName(category.iconName),
            color: _getColorFromHex(category.colorHex),
          ),
        ),
        title: Text(category.name),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Category'),
                content: const Text(
                  'Are you sure you want to delete this category?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );

            if (confirmed == true && category.categoryId != null) {
              await categoryService.deleteCategory(category.categoryId!);
            }
          },
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final authService = AuthService();
    final categoryService = CategoryService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final category = Category(
                  userId: authService.currentUserId,
                  name: nameController.text,
                  iconName: 'other',
                  colorHex: 'grey',
                );
                await categoryService.addCategory(category);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  IconData _getIconFromName(String name) {
    switch (name) {
      case 'restaurant':
        return Icons.restaurant;
      case 'car':
        return Icons.directions_car;
      case 'receipt':
        return Icons.receipt;
      case 'movie':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'hospital':
        return Icons.local_hospital;
      default:
        return Icons.more_horiz;
    }
  }

  Color _getColorFromHex(String hex) {
    switch (hex) {
      case 'orange':
        return Colors.orange;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      case 'green':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// ==================== PAYMENT METHODS SCREEN ====================
class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final paymentMethodService = PaymentMethodService();

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: StreamBuilder<List<PaymentMethod>>(
        stream: paymentMethodService.getUserPaymentMethods(
          authService.currentUserId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No payment methods yet'));
          }

          final methods = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: methods.length,
            itemBuilder: (context, index) {
              final method = methods[index];
              return _buildPaymentMethodItem(
                context,
                method,
                paymentMethodService,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddPaymentMethodDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPaymentMethodItem(
    BuildContext context,
    PaymentMethod method,
    PaymentMethodService service,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.payment)),
        title: Text(method.type),
        subtitle: Text(method.details),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Payment Method'),
                content: const Text('Are you sure?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );

            if (confirmed == true && method.methodId != null) {
              await service.deletePaymentMethod(method.methodId!);
            }
          },
        ),
      ),
    );
  }

  void _showAddPaymentMethodDialog(BuildContext context) {
    final typeController = TextEditingController();
    final detailsController = TextEditingController();
    final authService = AuthService();
    final service = PaymentMethodService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeController,
              decoration: const InputDecoration(
                labelText: 'Type (e.g., Credit Card)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: detailsController,
              decoration: const InputDecoration(labelText: 'Details'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (typeController.text.isNotEmpty) {
                final method = PaymentMethod(
                  userId: authService.currentUserId,
                  type: typeController.text,
                  details: detailsController.text,
                );
                await service.addPaymentMethod(method);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
