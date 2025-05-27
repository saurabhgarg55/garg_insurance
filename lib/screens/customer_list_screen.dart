import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/policy.dart';
import '../utils/database_helper.dart';
import 'add_customer_screen.dart'; // Import AddCustomerScreen for editing

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  _CustomerListScreenState createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Policy> _policies = [];
  List<Policy> _filteredPolicies = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPolicies();
    _searchController.addListener(_filterPolicies);
  }

  Future<void> _loadPolicies() async {
    final policies = await _dbHelper.getPolicies();
    setState(() {
      _policies = policies;
      _filteredPolicies = policies;
    });
  }

  void _filterPolicies() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPolicies = _policies.where((policy) {
        final customerNameLower = policy.customerName.toLowerCase();
        final policyTypeLower = policy.policyType.toLowerCase();
        final vehicleNumberLower = policy.vehicleNumber?.toLowerCase() ?? '';

        return customerNameLower.contains(query) ||
            policyTypeLower.contains(query) ||
            vehicleNumberLower.contains(query);
      }).toList();
    });
  }

  Future<void> _deletePolicy(Policy policy) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete ${policy.customerName}\'s policy?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _dbHelper.deletePolicy(policy.id!);
      _loadPolicies(); // Reload policies after deletion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${policy.customerName}\'s policy deleted.')),
      );
    }
  }

  void _editPolicy(Policy policy) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCustomerScreen(policy: policy), // Pass policy for editing
      ),
    ).then((_) => _loadPolicies()); // Reload policies when returning from edit screen
  }

  void _showPolicyDetails(Policy policy) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Policy Details'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Customer Name: ${policy.customerName}'),
                Text('Contact Number: ${policy.contactNumber}'),
                Text('Policy Type: ${policy.policyType}'),
                if (policy.policyType == 'Auto Policy') ...[
                  if (policy.autoPolicySubType != null)
                    Text('Auto Policy Sub Type: ${policy.autoPolicySubType}'),
                  if (policy.policyCompany != null)
                    Text('Policy Company: ${policy.policyCompany}'),
                  if (policy.policyStartDate != null)
                    Text('Policy Start Date: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(policy.policyStartDate!))}'),
                  if (policy.vehicleNumber != null)
                    Text('Vehicle Number: ${policy.vehicleNumber}'),
                ],
                Text('Coverage Amount: \$${policy.coverageAmount.toStringAsFixed(2)}'),
                Text('Premium Due Date: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(policy.premiumDueDate))}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/123.jpg',
              height: 40.0, // Adjust height as needed
            ),
            const SizedBox(width: 10), // Spacing between logo and text
            const Text('GARG INSURANCE'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by Name, Vehicle, or Policy Type',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _filteredPolicies.isEmpty
                ? const Center(child: Text('No customers found.'))
                : ListView.builder(
                    itemCount: _filteredPolicies.length,
                    itemBuilder: (context, index) {
                      final policy = _filteredPolicies[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: InkWell( // Make the card tappable for details
                          onTap: () => _showPolicyDetails(policy),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Customer Name: ${policy.customerName}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text('Policy Type: ${policy.policyType}'),
                                if (policy.policyType == 'Auto Policy' && policy.vehicleNumber != null)
                                  Text('Vehicle Number: ${policy.vehicleNumber}'),
                                const SizedBox(height: 4),
                                Text(
                                  'Premium Due Date: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(policy.premiumDueDate))}',
                                ),
                                const SizedBox(height: 10), // Spacing before buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => _editPolicy(policy),
                                      child: const Text('EDIT'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () => _deletePolicy(policy),
                                      child: const Text('DELETE', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
