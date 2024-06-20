import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String apiUrl = "http://10.0.2.2:3030/api/transactions"; // Remplacez par votre URL d'API backend
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          _transactions = json.decode(response.body);
        });
      } else {
        print("Failed to load transactions: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching transactions: $e");
    }
  }

  Future<void> addTransaction(String description, double amount) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'description': description,
          'amount': amount,
        }),
      );
      if (response.statusCode == 201) { // 201 for successful creation
        fetchTransactions();
      } else {
        print('Failed to add transaction: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding transaction: $e');
    }
  }

  Future<void> updateTransaction(int id, String description, double amount) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'description': description,
          'amount': amount,
        }),
      );
      if (response.statusCode == 200) {
        fetchTransactions();
      } else {
        print('Failed to update transaction: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating transaction: $e');
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      if (response.statusCode == 200) {
        fetchTransactions();
      } else {
        print('Failed to delete transaction: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting transaction: $e');
    }
  }

  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddTransactionDialog(onAdd: (description, amount) {
          addTransaction(description, amount);
        });
      },
    );
  }

  void _showEditTransactionDialog(int id, String description, double amount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditTransactionDialog(
          id: id,
          initialDescription: description,
          initialAmount: amount,
          onEdit: (newDescription, newAmount) {
            updateTransaction(id, newDescription, newAmount);
          },
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddTransactionDialog,
          ),
        ],
      ),
      body: _transactions.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _transactions.length,
        itemBuilder: (BuildContext context, int index) {
          final transaction = _transactions[index];
          return ListTile(
            title: Text(transaction['description']),
            subtitle: Text(transaction['amount'].toString()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _showEditTransactionDialog(
                      transaction['id'],
                      transaction['description'],
                      transaction['amount'].toDouble(),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    deleteTransaction(transaction['id']);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AddTransactionDialog extends StatefulWidget {
  final Function(String, double) onAdd;

  AddTransactionDialog({required this.onAdd});

  @override
  _AddTransactionDialogState createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  String _description = '';
  String _amount = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Transaction'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'Description'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
              onSaved: (value) {
                _description = value!;
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
              onSaved: (value) {
                _amount = value!;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: Text('Add'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              widget.onAdd(_description, double.parse(_amount));
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}

class EditTransactionDialog extends StatefulWidget {
  final int id;
  final String initialDescription;
  final double initialAmount;
  final Function(String, double) onEdit;

  EditTransactionDialog({
    required this.id,
    required this.initialDescription,
    required this.initialAmount,
    required this.onEdit,
  });

  @override
  _EditTransactionDialogState createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<EditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _description;
  late String _amount;

  @override
  void initState() {
    super.initState();
    _description = widget.initialDescription;
    _amount = widget.initialAmount.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Transaction'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _description,
              decoration: InputDecoration(labelText: 'Description'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
              onSaved: (value) {
                _description = value!;
              },
            ),
            TextFormField(
              initialValue: _amount,
              decoration: InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
              onSaved: (value) {
                _amount = value!;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: Text('Save'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              widget.onEdit(_description, double.parse(_amount));
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
