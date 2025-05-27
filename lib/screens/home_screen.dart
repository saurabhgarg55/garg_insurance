import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:excel/excel.dart'; // For generating Excel files
import 'package:path_provider/path_provider.dart'; // For getting directory path
import 'package:permission_handler/permission_handler.dart'; // For handling permissions
import 'dart:io'; // For File operations
import '../utils/database_helper.dart';
import '../models/policy.dart';
import 'add_customer_screen.dart';
import 'customer_list_screen.dart';
import 'package:fluttertoast/fluttertoast.dart'; // For showing toast messages

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  int _totalCustomers = 0;
  int _totalPolicies = 0;
  int _upcomingRenewalsCount = 0;
  List<Policy> _upcomingRenewals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSummaryData();
  }

  Future<void> _fetchSummaryData() async {
    setState(() {
      _isLoading = true;
    });

    final policies = await _databaseHelper.getPolicies();

    // Calculate total policies
    _totalPolicies = policies.length;

    // Calculate total unique customers
    final uniqueCustomers = policies.map((p) => p.customerName).toSet();
    _totalCustomers = uniqueCustomers.length;

    // Calculate upcoming renewals for the current week
    _upcomingRenewals = _getPoliciesDueThisWeek(policies);
    _upcomingRenewalsCount = _upcomingRenewals.length;

    setState(() {
      _isLoading = false;
    });
  }

  List<Policy> _getPoliciesDueThisWeek(List<Policy> allPolicies) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final endOfWeek = startOfWeek.add(const Duration(days: 6)); // Sunday

    return allPolicies.where((policy) {
      try {
        final dueDate = DateTime.parse(policy.premiumDueDate);
        return dueDate.isAfter(now.subtract(const Duration(days: 1))) && // Due from today onwards
               dueDate.isBefore(endOfWeek.add(const Duration(days: 1))); // Up to end of this week
      } catch (e) {
        print('Error parsing date for policy ${policy.id}: ${policy.premiumDueDate} - $e');
        return false;
      }
    }).toList();
  }

  Future<void> _downloadCustomerDataAsExcel() async {
    try {
      // Request storage permission
      var status = await Permission.storage.request();
      if (status.isDenied) {
        Fluttertoast.showToast(msg: "Storage permission denied. Cannot save file.");
        return;
      }
      if (status.isPermanentlyDenied) {
        Fluttertoast.showToast(msg: "Storage permission permanently denied. Please enable it from app settings.");
        openAppSettings(); // Opens app settings for the user
        return;
      }

      final policies = await _databaseHelper.getPolicies();

      if (policies.isEmpty) {
        Fluttertoast.showToast(msg: "No customer data to export.");
        return;
      }

      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Customer Data'];

      // Add headers
      List<String> headers = [
        'Customer Name',
        'Policy Type',
        'Contact Number',
        'Vehicle Number',
        'Coverage Amount',
        'Premium Due Date'
      ];
      sheetObject.appendRow(headers);

      // Add data rows
      for (var policy in policies) {
        sheetObject.appendRow([
          policy.customerName,
          policy.policyType,
          policy.contactNumber,
          policy.vehicleNumber ?? 'N/A',
          policy.coverageAmount,
          DateFormat('yyyy-MM-dd').format(DateTime.parse(policy.premiumDueDate)),
        ]);
      }

      // Get the directory for saving the file
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getDownloadsDirectory(); // For Android 10+ public downloads
        directory ??= await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory(); // For iOS
      } else {
        directory = await getApplicationDocumentsDirectory(); // For other platforms
      }

      if (directory == null) {
        Fluttertoast.showToast(msg: "Could not get download directory.");
        return;
      }

      String filePath = '${directory.path}/customer_data_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      File file = File(filePath);

      // Save the file
      List<int>? excelBytes = excel.encode();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
        Fluttertoast.showToast(msg: "Customer data exported to $filePath");
      } else {
        Fluttertoast.showToast(msg: "Failed to generate Excel file.");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error exporting data: $e");
      print("Error exporting data: $e");
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadCustomerDataAsExcel,
            tooltip: 'Download Customer Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Summary',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Customers',
                          _totalCustomers.toString(),
                          Icons.people,
                          Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Policies',
                          _totalPolicies.toString(),
                          Icons.description,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryCard(
                    'Upcoming Renewals (This Week)',
                    _upcomingRenewalsCount.toString(),
                    Icons.calendar_today,
                    Colors.orange,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Premium Due Dates (Current Week)',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _upcomingRenewals.isEmpty
                      ? const Center(
                          child: Text('No upcoming renewals this week.'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _upcomingRenewals.length,
                          itemBuilder: (context, index) {
                            final policy = _upcomingRenewals[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Customer: ${policy.customerName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Policy Type: ${policy.policyType}'),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Due Date: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(policy.premiumDueDate))}',
                                      style: const TextStyle(color: Colors.redAccent),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
                            ).then((_) => _fetchSummaryData()); // Refresh data on return
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                          child: const Text('Add Customer'),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CustomerListScreen()),
                            ).then((_) => _fetchSummaryData()); // Refresh data on return
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                          child: const Text('View Customers'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
